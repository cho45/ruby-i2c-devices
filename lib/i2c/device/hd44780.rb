# coding: utf-8

require "i2c"

# I2C interface with HD44780 compatible commands
class HD44780 < I2CDevice
	MAP = Hash[
		[
			"｡｢｣､・ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ".split(//).map {|c|
				c.force_encoding(Encoding::BINARY)
			},
			(0b10100001..0b11011111).map {|c|
				c.chr
			}
		].transpose
	]

	def initialize(args)
		super
		@lines = []
		initialize_lcd
	end

	def initialize_lcd
		function_set(1, 1, 0)
		sleep 4.1e-3
		function_set(1, 1, 0)
		sleep 100e-6
		function_set(1, 1, 0)
		function_set(1, 1, 0)
		display_on_off_control(1, 0, 0)
		clear
	end

	def put_line(line, str, force=false)
		str.force_encoding(Encoding::BINARY)
		str.gsub!(/#{MAP.keys.join('|')}/, MAP)

		str = "%- 16s" % str

		if force || str != @lines[line]
			# set ddram address
			set_ddram_address(0x40 * line)
			sleep 60e-6
			i2cset(*str.unpack("C*").map {|i| [0x80, i] }.flatten)
			sleep 60e-6
		end
		@lines[line] = str
	end

	# Usage:
	# lcd.define_character(0, [
	# 	0,1,1,1,0,
	# 	1,0,0,0,1,
	# 	1,1,0,1,1,
	# 	1,0,1,0,1,
	# 	1,1,0,1,1,
	# 	1,0,0,0,1,
	# 	1,0,0,0,1,
	# 	0,1,1,1,0,
	# ])
	def define_character(n, array)
		raise "n < 8" unless n < 8
		raise "array size must be 40 (5x8)" unless array.size == 40

		array = array.each_slice(5).map {|i|
			i.inject {|r,i| (r << 1) + i }
		}
		set_cgram_address(8 * n)
		sleep 60e-6
		i2cset(*array.map {|i| [0x80, i] }.flatten)
		sleep 60e-6
	end

	def clear
		@lines.clear
		clear_display
	end

	def clear_display
		i2cset(0, 0b00000001)
		sleep 2.16e-3
	end

	def return_home
		i2cset(0, 0b00000010)
		sleep 1.52e-3
	end

	# i_d : increment or decrement: 1: increment, 0: decrement
	# s   : shift entire display: 1: left, 0: right
	def entry_mode_set(i_d, s)
		i2cset(0, 0b00000100 | (i_d<<1) | (s))
		sleep 60e-6
	end

	# d: set entire display on/off
	# c: cursor on/off
	# b: blink cursor
	def display_on_off_control(d, c, b)
		i2cset(0, 0b00001000 | (d<<2) | (c<<1) | (b))
		sleep 60e-6
	end

	def cursor_or_display_shift(s_c, r_l)
		i2cset(0, 0b00010000 | (s_c<<3) | (r_l<<2))
		sleep 60e-6
	end

	# dl  data_length: 1: 8bit, 0: 4bit
	# n   number_of_display_lines: 1: 2-line, 0: 1-line
	# f   character_font: 1: double font, 0: normal
	def function_set(dl, n, f)
		i2cset(0, 0b00100000 | (dl<<4) | (n<<3) | (f<<2))
		sleep 60e-6
	end

	def set_cgram_address(address)
		address = address & 0b00111111
		i2cset(0, 0b01000000 | address)
		sleep 60e-6
	end

	def set_ddram_address(address)
		address = address & 0b01111111
		i2cset(0, 0b10000000 | address)
		sleep 60e-6
	end

	def read_busy_flag_and_address
		read = i2cget(0b01000000)
		{
			:busy => (read & 0b10000000) != 0,
			:address_counter => read & 0b01111111
		}
	end
end
