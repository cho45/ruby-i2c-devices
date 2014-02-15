# coding: utf-8

require "i2c"

# Note: This device only run under speed=50kHz
class ACM1602NI < I2CDevice
	MAP = Hash[
		[
			"｡｢｣､・ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ".split(//).map {|c|
				c.force_encoding(Encoding::BINARY)
			},
			(0xa1..0xdf).map {|c|
				c.chr
			}
		].transpose
	]

	def initialize(address=0x50, path=nil)
		super
		@lines = []
		initialize_lcd
	end

	undef i2cget
	def initialize_lcd
		# function set
		i2cset(0, 0b00111100)
		sleep 53e-6
		# display on/off control
		i2cset(0, 0b00001100)
		sleep 53e-6
		clear
	end

	def clear
		@lines.clear
		i2cset(0, 0b00000001)
		sleep 2.16e-3
	end

	def put_line(line, str, force=false)
		str.force_encoding(Encoding::BINARY)
		str.gsub!(/#{MAP.keys.join('|')}/, MAP)

		str = "%- 16s" % str

		if force || str != @lines[line]
			# set ddram address
			i2cset(0, 0b10000000 + (0x40 * line))
			sleep 53e-6
			i2cset(*str.unpack("C*").map {|i| [0x80, i] }.flatten)
			sleep 53e-6
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
		i2cset(0, 0b01000000 + (8 * n))
		sleep 53e-6
		i2cset(*array.map {|i| [0x80, i] }.flatten)
		sleep 53e-6
	end
end

