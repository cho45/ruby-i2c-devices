require "i2c"
=begin
Generic software I2C Driver based on /sys/class/gpio.
THIS MODULE WORKS WITH VERY SLOW SPEED ABOUT JUST 1kHz (normaly 100kHz).
=end

module I2CDevice::Driver
	class GPIO
		@@DEBUG = false

		def self.export(pin)
			File.open("/sys/class/gpio/export", "w") do |f|
				f.syswrite(pin)
			end
		end

		def self.unexport(pin)
			File.open("/sys/class/gpio/unexport", "w") do |f|
				f.syswrite(pin)
			end
		end

		def self.direction(pin, direction)
			# [:in, :out, :high, :low].include?(direction) or raise "direction must be :in, :out, :high or :low"
			File.open("/sys/class/gpio/gpio#{pin}/direction", "w") do |f|
				f.syswrite(direction)
			end
		end

		def self.read(pin)
			File.open("/sys/class/gpio/gpio#{pin}/value", "r") do |f|
				f.sysread(1).to_i
			end
		end

		def self.write(pin, val)
			File.open("/sys/class/gpio/gpio#{pin}/value", "w") do |f|
				f.syswrite(val ? "1" : "0")
			end
		end

		def self.finalizer(ports)
			proc do
				ports.each do |pin|
					GPIO.unexport(pin)
				end
			end
		end

		attr_reader :sda, :scl, :speed

		def initialize(opts={})
			@sda = opts[:sda] or raise "opts[:sda] = [gpio pin number] is requied"
			@scl = opts[:scl] or raise "opts[:scl] = [gpio pin number] is requied"
			@speed = opts[:speed] || 1 # kHz but insane
			@clock = 1.0 / (@speed * 1000)

			begin
				GPIO.export(@sda)
				GPIO.export(@scl)
			rescue Errno::EBUSY => e
			end
			ObjectSpace.define_finalizer(self, self.class.finalizer([@scl, @sda]))
			begin
				GPIO.direction(@sda, :high)
				GPIO.direction(@scl, :high)
				GPIO.direction(@sda, :in)
				GPIO.direction(@scl, :in)
			rescue Errno::EACCES => e # writing to gpio after export is failed in a while
				retry
			end
		end

		def i2cget(address, param, length=1)
			ret = ""
			start_condition
			unless write( (address << 1) + 0)
				raise I2CDevice::I2CIOError, "Unknown slave device (address:#{address})"
			end
			write(param)
			stop_condition
			start_condition
			unless write( (address << 1) + 1)
				raise I2CDevice::I2CIOError, "Unknown slave device (address:#{address})"
			end
			length.times do |n|
				ret << read(n != length - 1).chr
			end
			ret
		ensure
			stop_condition
		end

		def i2cset(address, *data)
			sent = 0
			start_condition
			unless write( (address << 1) + 0)
				raise I2CDevice::I2CIOError, "Unknown slave device (address:#{address})"
			end
			data.each do |c|
				sent += 1
				unless write(c)
					break
				end
			end
			sent
		ensure
			stop_condition
		end

		private

		def start_condition
			p :start_condition if @@DEBUG
			sleep @clock
			GPIO.direction(@sda, :in)
			GPIO.direction(@scl, :in)
			if GPIO.read(@scl) == 0
				raise I2CDevice::I2CBUSBusy, "BUS is busy"
			end

			sleep @clock / 2
			GPIO.direction(@scl, :high)
			sleep @clock / 2
			GPIO.direction(@sda, :low)
			sleep @clock
		end

		def stop_condition
			p :stop_condition if @@DEBUG
			GPIO.direction(@scl, :low)
			sleep @clock / 2
			GPIO.direction(@sda, :low)
			sleep @clock / 2
			GPIO.direction(@scl, :in)
			sleep @clock / 2
			GPIO.direction(@sda, :in)
			sleep @clock / 2
		end

		def write(byte)
			p [:write, byte] if @@DEBUG
			GPIO.direction(@scl, :low)
			sleep @clock

			7.downto(0) do |n|
				GPIO.direction(@sda, byte[n] == 1 ? :high : :low)
				GPIO.direction(@scl, :in)
				until GPIO.read(@scl) == 1
					# clock streching
					sleep @clock
				end
				sleep @clock
				GPIO.direction(@scl, :low)
				GPIO.write(@sda, false)
				sleep @clock
			end

			GPIO.direction(@sda, :in)
			GPIO.direction(@scl, :in)
			sleep @clock / 2
			ack = GPIO.read(@sda) == 0
			sleep @clock / 2
			while GPIO.read(@scl) == 0
				sleep @clock
			end
			GPIO.direction(@scl, :low)
			ack
		end

		def read(ack=true)
			p [:read, ack] if @@DEBUG
			ret = 0

			GPIO.direction(@scl, :low)
			sleep @clock
			GPIO.direction(@sda, :in)

			8.times do
				GPIO.direction(@scl, :in)
				sleep @clock / 2
				ret = (ret << 1) | GPIO.read(@sda)
				sleep @clock / 2
				GPIO.direction(@scl, :low)
				sleep @clock
			end

			GPIO.direction(@sda, ack ? :low : :high)

			GPIO.write(@scl, true)
			sleep @clock
			GPIO.write(@scl, false)
			sleep @clock
			ret
		end
	end
end

