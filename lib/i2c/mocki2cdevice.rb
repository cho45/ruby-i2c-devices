#!/usr/bin/env ruby

class MockI2CDevice
	attr_reader :memory
	attr_reader :ioctl
	attr_reader :state

	def initialize
		@temp = Tempfile.new("i2c")
		@ioctl = []
		@memory = [ 0 ]
		@address = nil
		@state = nil
	end

	def path
		@temp.path
	end

	def ioctl(cmd, arg)
		@ioctl = [cmd, arg]
		self
	end

	def open
		@address = nil
		@state = :init
		self
	end

	def close
		@address = nil
		@state = nil
		self
	end

	def syswrite(buf)
		buf.unpack("C*").each do |c|
			case @state
			when :init
				# p "@address = 0x%02x" % c
				@address = c
				@state = :wait
			when :wait
				# p "@memory[0x%02x] = 0b%08b" % [@address, c]
				@memory[@address] = c
				@address += 1
			end
		end
	end

	def sysread(size)
		ret = []
		case @state
		when :init
			raise "Invalid State"
		when :wait
			size.times do
				ret << @memory[@address]
				@address += 1
			end
		end
		ret.pack("C*")
	end
end


