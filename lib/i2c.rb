# Generic abstract class for I2C manipulation.
class I2CDevice
	VERSION = "0.0.5"

	# Super class of all of this library.
	class I2CException < Exception; end
	class I2CIOError < I2CException; end
	class I2CBUSBusy < I2CIOError; end

	# Slave address
	attr_accessor :address

	# <tt>args[:address]</tt> :: [Integer] 7-bit slave address without r/w bit. MSB is always 0.
	# <tt>args[:driver]</tt>  :: [I2CDevice::Driver::I2CDev] Instance of driver class
	def initialize(args={})
		if args[:driver].nil?
			require "i2c/driver/i2c-dev"
			args[:driver] = I2CDevice::Driver::I2CDev.new
		end

		@driver  = args[:driver]
		@address = args[:address] or raise I2CException, "args[:address] required"
	end

	# This method read data from slave with following process:
	#
	# 1. Write `param` to slave
	# 2. re-start
	# 3. Read data until NACK or `length`
	#
	# <tt>param</tt>    :: [Integer] First writing byte. Typically, this is slave memory address.
	# <tt>length=1</tt> :: [Integer] Read bytes length
	# Returns           :: [String] Bytes
	def i2cget(param, length=1)
		@driver.i2cget(@address, param, length)
	end

	# Write _data_ to slave.
	# <tt>data</tt>     :: [Array[Integer]] Writing bytes array.
	# Returns           :: [String] Wrote bytes
	def i2cset(*data)
		@driver.i2cset(@address, *data)
	end
end

