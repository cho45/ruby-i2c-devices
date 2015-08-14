# coding: utf-8

require "i2c"
require "i2c/device/hd44780"

class I2CDevice::AQM0802A < I2CDevice::HD44780
	def initialize(args={})
		args[:address] ||= 0x3e
		super
		@is = 0
	end

	# This device does not support read
	undef i2cget

	def initialize_lcd
		function_set(1, 1, 0, 1)
		internal_osc_frequency(0, 0b100)
		power_icon_control_contrast_set(0, 1, 0b10000)
		follower_control(1, 0b100)
		function_set(1, 1, 0, 0)
		display_on_off_control(1, 0, 0)
		clear
	end


	# Must set is = 1 by function_set before call.
	def internal_osc_frequency(bs, f)
		raise "is must be 1" unless @is == 1
		f &= 0b111
		i2cset(0, 0b00010000 | (bs << 3) | (f))
		sleep 26.3e-6
	end

	def power_icon_control_contrast_set(ion, bon, c)
		c &= 0b111111
		# contrast_set
		i2cset(0, 0b01110000 | (c&0b111))
		sleep 26.3e-6
		# power_icon_control_contrast_set
		i2cset(0, 0b01010000 | (ion<<3) | (bon<<2) | (c>>3))
		sleep 26.3e-6
	end

	def follower_control(fon, rab)
		i2cset(0, 0b01100000 | (fon<<3) | rab)
		sleep 300e-3
	end

	# <tt>is</tt> :: [Integer]  Instruction set 1: extension, 0: normal
	def function_set(dl, n, f, is)
		@is = is
		i2cset(0, 0b00100000 | (dl<<4) | (n<<3) | (f<<2) | (is))
		sleep 37e-6
	end

	def put_line(line, str, force=false)
		str.force_encoding(Encoding::BINARY)
		str.gsub!(/#{MAP.keys.join('|')}/, MAP)
		str = "%- 8s" % str
		if force || str != @lines[line]
			# set ddram address
			set_ddram_address(line<<6) # line is 0 or 1
			sleep 60e-6
			i2cset(0b01000000, *str.unpack("C*"))
			sleep 60e-6
		end
		@lines[line] = str
	end
end
