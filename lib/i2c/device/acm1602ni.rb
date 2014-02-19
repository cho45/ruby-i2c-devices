# coding: utf-8

require "i2c/device/hd44780"

# 16x02 LCD module with I2C.
# Note: This device only run under speed=50kHz.
# http://akizukidenshi.com/catalog/g/gP-05693/
class I2CDevice::ACM1602NI < I2CDevice::HD44780
	def initialize(args={})
		args[:address] ||= 0x50
		super
		@lines = []
		initialize_lcd
	end

	undef i2cget
	undef read_busy_flag_and_address
end

