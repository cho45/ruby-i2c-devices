#!/usr/bin/env ruby

require "i2c"

module I2CDevice::Driver
	# Abstract class for I2CDevice::Driver
	class Base
		include I2CDevice::Driver
	end

	# Low-level method for i2cget
	# Driver must implement this.
	# <tt>address</tt> :: [Integer] 7-bit slave address without r/w bit. MSB is always 0.
	# <tt>data</tt>    :: [Array[Integer]] Writing bytes array.
	# Returns          :: [String] Wrote bytes
	def i2cget(address, param, length=1)
		raise NotImplementedError
	end

	# Low-level method for i2cset
	# Driver must implement this.
	# <tt>address</tt> :: [Integer] 7-bit slave address without r/w bit. MSB is always 0.
	# <tt>data</tt>    :: [Array[Integer]] Writing bytes array.
	# Returns          :: [String] Wrote bytes
	def i2cset(address, *data)
		raise NotImplementedError
	end
end

