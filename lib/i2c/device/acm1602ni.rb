# coding: utf-8

require "i2c"
require "i2c/device/hd44780"

# Note: This device only run under speed=50kHz
class ACM1602NI < HD44780
	def initialize(address=0x50, path=nil)
		super
		@lines = []
		initialize_lcd
	end

	undef i2cget
end

