class I2CDevice
	VERSION = "0.0.1"

	class I2CException < Exception; end
	class I2CIOError < I2CException; end

	attr_accessor :address

	def initialize(args)
		if args[:driver].nil?
			require "i2c/driver/i2c-dev"
			args[:driver] = I2CDevice::Driver::I2CDev.new
		end

		@driver  = args[:driver]
		@address = args[:address] or raise I2CException, "args[:address] required"
	end

	def i2cget(param, length=1)
		@driver.i2cget(@address, param, length)
	end

	def i2cset(*data)
		@driver.i2cset(@address, *data)
	end
end

