#!/usr/bin/env ruby


module I2CDevice::Driver
	# Abstract class for I2CDevice::Driver
	class  I2CDevice::Driver::Base
		include I2CDevice::Driver
	end

	def i2cget(address, param, length=1)
		raise NotImplementedError
	end

	def i2cset(address, *data)
		raise NotImplementedError
	end
end

