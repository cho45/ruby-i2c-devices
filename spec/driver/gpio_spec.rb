#!rspec

$LOAD_PATH.unshift "lib"

require "i2c"
require "i2c/driver/gpio"
require "tempfile"

class GPIOTimeline
	attr_reader :events

	def initialize
		@timeline = {}
		@pins = []
		@events = []
		@defaults = {}
		@watchers = {}
	end

	def define(pin)
		unless @timeline.include?(pin)
			default(pin, 0)
			@timeline[pin] = []
			@watchers[pin] = []
			@pins << pin
		end
	end

	def add(pin, state)
		event = {
			time:  Time.now,
			state: state,
			pin: pin,
		}
		@events << event
		@timeline[pin] << event
		@watchers[pin].each do |watcher|
			watcher[:count][:total] += 1
			watcher[:count][state.zero?? :low : :high] += 1
			watcher[:block].call(state, watcher[:count])
		end
	end

	def mark(label, position=:top)
		event = {
			time: Time.now,
			label: label,
			position: position,
		}
		@events << event
	end

	def default(pin, state=nil)
		unless state.nil?
			@defaults[pin] = state
		end
		@defaults[pin]
	end

	def state(pin)
		@timeline[pin].last[:state]
	end

	def watch(pin, &block)
		watcher= {
			pin: pin,
			block: block,
			count: {
				total: 0,
				low: 0,
				high: 0,
			}
		}
		@watchers[pin] << watcher
		unwatch = lambda {
			@watchers[pin].delete(watcher)
		}
	end

	def dump
		require "cairo"

		width  = 1240
		height = 300

		surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, width, height)
		context = Cairo::Context.new(surface)

		total = @events.last[:time] - @events.first[:time]
		start = @events.first[:time]
		px_per_sec = (width - 20) / total

		h = 50

		context.select_font_face("Lucida Console")
		context.line_width = 3
	
		@events.select {|i| i[:label] }.each do |event|
			n = event[:time] - start
			label = event[:label]
			context.set_source_rgb(0.7, 0.7, 0.7)
			context.stroke do
				context.move_to(n * px_per_sec, 0)
				context.line_to(n * px_per_sec, height)
			end
			context.set_source_rgb(0.3, 0.3, 0.3)
			context.move_to(n * px_per_sec + 5, event[:position] == :top ? 20 : height - 20)
			context.set_font_size(10)
			context.show_text(label.to_s)
		end

		context.set_source_rgb(0.3, 0.3, 0.3)
		context.line_width = 2

		pin_count = 1
		@pins.each do |pin|
			context.save do
				prev = 0
				context.translate(0, 100 * pin_count)

				context.move_to(0, prev)
				context.line_to(10, prev)

				context.translate(10, 0)

				@timeline[pin].each do |event|
					n = event[:time] - start

					context.line_to(n * px_per_sec, prev * -h)
					context.line_to(n * px_per_sec, event[:state] * -h)
					prev = event[:state]
				end

				context.line_to(width, prev * -h)

				context.stroke
			end
			pin_count += 1
		end

		surface.write_to_png("/tmp/dump.png")
	end
end

describe I2CDevice::Driver::GPIO do
	before do
		@timeline = timeline = GPIOTimeline.new

		I2CDevice::Driver::GPIO.define_singleton_method(:export) do |pin|
			timeline.define(pin)
		end

		I2CDevice::Driver::GPIO.define_singleton_method(:unexport) do |pin|
		end

		I2CDevice::Driver::GPIO.define_singleton_method(:direction) do |pin, direction|
			# p [:direction, pin]
			state = 1
			case direction
			when :in
				state = timeline.default(pin) # pulled-up
			when :out
				state = 0
			when :high
				state = 1
			when :low
				state = 0
			end
			timeline.add(pin, state)
		end

		I2CDevice::Driver::GPIO.define_singleton_method(:read) do |pin|
			timeline.state(pin)
		end

		I2CDevice::Driver::GPIO.define_singleton_method(:write) do |pin, val|
			timeline.add(pin, val ? 1 : 0)
		end

		@driver = I2CDevice::Driver::GPIO.new(
			sda: 23,
			scl: 24,
		)
		@timeline.events.clear
		@timeline.default(@driver.scl, 1)
		@timeline.default(@driver.sda, 1)
	end

	describe "i2c protocol" do
		it "should set start condition correctly" do
			@driver.send(:start_condition)
			expect(@timeline.state(@driver.scl)).to be(1)
			expect(@timeline.state(@driver.sda)).to be(0)
			expect(@timeline.events.map {|i| [i[:pin], i[:state]] }).to eq([[@driver.sda, 1], [@driver.scl, 1], [@driver.scl, 1], [@driver.sda, 0]])
		end

		it "should throw exception when bus is busy" do
			@timeline.default(@driver.scl, 0)
			expect { @driver.send(:start_condition) }.to raise_error(I2CDevice::I2CBUSBusy)
		end

		it "should set stop condition correctly" do
			@driver.send(:start_condition)

			@timeline.events.clear
			@driver.send(:stop_condition)
			expect(@timeline.events.map {|i| [i[:pin], i[:state]] }).to eq([ [@driver.scl, 0], [@driver.sda, 0], [@driver.scl, 1], [@driver.sda, 1] ])
			expect(@timeline.state(@driver.scl)).to be(1)
			expect(@timeline.state(@driver.sda)).to be(1)
		end

		it "should write 1 byte correctly and receive nack" do
			@timeline.mark(:start)
			@driver.send(:start_condition)

			@timeline.mark(:write)
			ret = @driver.send(:write, 0b01010011)
			expect(@timeline.events.drop_while {|i| i[:label] != :write }.select {|i| i[:pin] == @driver.scl }.map {|i| i[:state] }).to eq([0, 1] * 9 + [0])
			expect(ret).to be(false)
			expect(@timeline.state(@driver.scl)).to be(0)

			@timeline.mark(:stop)
			@driver.send(:stop_condition)
		end

		it "should write 1 byte correctly and receive ack" do
			@timeline.mark(:start)
			@driver.send(:start_condition)

			unwatch = @timeline.watch(@driver.scl) do |state, count|
				case
				when count[:high] == 8 && state == 0
					# return ack
					@timeline.default(@driver.sda, 0)
				when count[:high] == 9 && state == 1
					@timeline.mark("ack")
				when count[:high] == 9 && state == 0
					@timeline.default(@driver.sda, 1)
					unwatch.call
				end
			end

			@timeline.mark(:write)
			ret = @driver.send(:write, 0b11111111)
			expect(@timeline.events.drop_while {|i| i[:label] != :write}.select {|i| i[:pin] == @driver.scl }.map {|i| i[:state] }).to eq([0, 1] * 9 + [0])
			expect(ret).to be(true)
			expect(@timeline.state(@driver.scl)).to be(0)

			@timeline.mark(:stop)
			@driver.send(:stop_condition)
		end

		it "should read 1 byte correctly and return ack" do
			@timeline.mark(:start)
			@driver.send(:start_condition)

			send = 0b00000000
			unwatch = @timeline.watch(@driver.scl) do |state, count|
				case
				when count[:high] < 8 && state == 0
					# send bit
					bit = send[ 7 - count[:high] ]
					@timeline.default(@driver.sda, bit)
					@timeline.add(@driver.sda, bit)
				when count[:high] == 9 && state == 1
					# read ack
					@timeline.mark(:ack)
					expect(@timeline.state(@driver.sda)).to be(0)
					unwatch.call
					@timeline.default(@driver.sda, 1)
				end
			end
			@timeline.mark(:read)
			ret = @driver.send(:read, true)
			expect(ret).to be(send)

			send = 0b01010101
			unwatch = @timeline.watch(@driver.scl) do |state, count|
				case
				when count[:high] < 8 && state == 0
					# send bit
					bit = send[ 7 - count[:high] ]
					@timeline.default(@driver.sda, bit)
					@timeline.add(@driver.sda, bit)
				when count[:high] <= 8 && state == 1
					@timeline.mark("#{8 - count[:high]}", :bottom)
				when count[:high] == 9 && state == 1
					# read ack
					@timeline.mark(:ack)
					expect(@timeline.state(@driver.sda)).to be(0)
					unwatch.call
					@timeline.default(@driver.sda, 1)
				end
			end
			ret = @driver.send(:read, true)
			expect(ret).to be(send)

			@timeline.mark(:stop)
			@driver.send(:stop_condition)
		end

		it "should read 1 byte correctly and return nack" do
			@timeline.mark(:start)
			@driver.send(:start_condition)

			send = 0b01010101
			unwatch = @timeline.watch(@driver.scl) do |state, count|
				case
				when count[:high] < 8 && state == 0
					# send bit
					bit = send[ 7 - count[:high] ]
					@timeline.default(@driver.sda, bit)
					@timeline.add(@driver.sda, bit)
				when count[:high] == 9 && state == 1
					# read ack
					@timeline.mark(:nack)
					expect(@timeline.state(@driver.sda)).to be(1)
					unwatch.call
					@timeline.default(@driver.sda, 1)
				end
			end
			ret = @driver.send(:read, false)
			expect(ret).to be(send)

			@timeline.mark(:stop)
			@driver.send(:stop_condition)
		end
	end

	describe "i2c abstract interface:" do
		context "unknown slave address:" do
			describe "i2cset" do
				it "should throw exception on unknown slave address" do
					expect { @driver.i2cset(0x20, 0x00) }.to raise_error(I2CDevice::I2CIOError)

					expect(@timeline.state(@driver.scl)).to be(1)
					expect(@timeline.state(@driver.sda)).to be(1)
				end
			end

			describe "i2cget" do
				it "should throw exception on unknown slave address" do
					expect { @driver.i2cget(0x20, 0x00) }.to raise_error(I2CDevice::I2CIOError)

					expect(@timeline.state(@driver.scl)).to be(1)
					expect(@timeline.state(@driver.sda)).to be(1)
				end
			end
		end

		context "valid slave address:" do
			before do
				@status = :stop
				@received = []
				@memory = [0x00] * 5
				@max_receive = 3

				unwatch_scl = nil
				@timeline.watch(@driver.sda) do |state, count|
					case
					when @timeline.state(@driver.scl) == 1 && state == 0
						@status  = :start
						@timeline.mark(@status)
						address = 0
						data    = 0
						rw      = nil
						read_address = 0
						ack     = 1
						unwatch_scl.call if unwatch_scl
						unwatch_scl = @timeline.watch(@driver.scl) do |state, count|
							# p [@status, state, count]
							case @status
							when :start
								case
								when state == 1 && count[:high] < 8
									@timeline.mark(8 - count[:high], :bottom)
									address = (address << 1) | @timeline.state(@driver.sda)
								when state == 1 && count[:high] == 8
									@timeline.mark('rw', :bottom)
									rw = @timeline.state(@driver.sda)
									# p " 0b%08b == 0b%08b %02x" % [0x20, address, address]
								when state == 0 && count[:high] == 8
									if address == 0x20
										# ack
										@timeline.default(@driver.sda, 0)
									else
										@status = :unkown
										@timeline.mark(@status)
									end
								when state == 1 && count[:high] == 9
									@timeline.mark('ack')
								when state == 0 && count[:high] == 9
									# reset
									count[:high] = 0
									count[:low] = 0
									@timeline.default(@driver.sda, 1)
									if rw.zero?
										@status = :write
									else
										@status = :read
										read_address = @received[0]
									end
								end
							when :write
								case
								when state == 1 && count[:high] <= 8
									@timeline.mark(8 - count[:high], :bottom)
									data = (data << 1) | @timeline.state(@driver.sda)
								when state == 0 && count[:high] == 8
									if @received.size < @max_receive
										@received << data
										# ack
										@timeline.default(@driver.sda, 0)
									end
								when state == 1 && count[:high] == 9
									@timeline.mark(@received.size <= @max_receive ? 'ack' : 'nack')
								when state == 0 && count[:high] == 9
									# reset
									data = 0
									count[:high] = 0
									count[:low] = 0
									@timeline.default(@driver.sda, 1)
									unless @received.size <= @max_receive
										@status = :stop
									end
								end
							when :read
								case
								when state == 0 && count[:high] < 8
									# send bit
									bit = @memory[read_address][ 7 - count[:high] ]
									@timeline.default(@driver.sda, bit)
									@timeline.add(@driver.sda, bit)
								when state == 1 && count[:high] <= 8
									@timeline.mark(8 - count[:high], :bottom)
								when state == 0 && count[:high] == 8
									@timeline.default(@driver.sda, 1)
								when state == 1 && count[:high] == 9
									ack = @timeline.state(@driver.sda)
									if ack == 0
										@timeline.mark("ack")
									else
										@timeline.mark("nack")
										@status = :stop
									end
								when state == 0 && count[:high] == 9
									read_address += 1
									count[:high] = 0
									count[:low] = 0
								end
							end
						end
					when @timeline.state(@driver.scl) == 1 && state == 1
						@status = :stop
						@timeline.mark(@status)
						unwatch_scl.call
					end
				end
			end

			describe "i2cset" do
				it "should works successfully" do
					wrote = @driver.i2cset(0x20, 0x0f)
					expect(wrote).to be(1)
					expect(@received).to eq([0x0f])

					expect(@timeline.state(@driver.scl)).to be(1)
					expect(@timeline.state(@driver.sda)).to be(1)
				end

				it "should write until nack" do
					@max_receive = 3
					wrote = @driver.i2cset(0x20, 0x01, 0x02, 0x03, 0x04, 0x05)
					expect(wrote).to be(3)
					expect(@received).to eq([0x01, 0x02, 0x03])

					expect(@timeline.state(@driver.scl)).to be(1)
					expect(@timeline.state(@driver.sda)).to be(1)
				end
			end

			describe "i2cget" do
				it "should works successfully" do
					@max_receive = 1
					@memory = (0..4).to_a
					got = @driver.i2cget(0x20, 0x01)
					expect(got).to eq("\x01")

					expect(@timeline.state(@driver.scl)).to be(1)
					expect(@timeline.state(@driver.sda)).to be(1)
				end

				it "should works with length argument" do
					@max_receive = 1
					@memory = (0..4).to_a
					got = @driver.i2cget(0x20, 0x01, 3)
					expect(got).to eq("\x01\x02\x03")

					expect(@timeline.state(@driver.scl)).to be(1)
					expect(@timeline.state(@driver.sda)).to be(1)
				end
			end
		end
	end
end
