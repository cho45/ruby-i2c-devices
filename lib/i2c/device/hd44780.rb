# coding: utf-8

require "i2c"

# I2C interface with HD44780 compatible commands
class I2CDevice::HD44780 < I2CDevice
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

	def initialize(args={})
		super
		@lines = []
		initialize_lcd
	end

	# Initialize LCD controller sequence
	# Display is cleared.
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

	# <tt>line</tt>  :: [Integer]      Line number
	# <tt>str</tt>   :: [String]       Display string
	# <tt>force</tt> :: [true | false] Write data forcely.
	#
	# Note: This method keep previous put_line strings and does not write without change.
	# You must specify _force_ to override this behaviour.
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

	# <tt>n</tt>     :: [Integer] Character code.
	# <tt>array</tt> :: [Array[Integer]] Character data.
	# Usage:
	#     lcd.define_character(0, [
	#         0,1,1,1,0,
	#         1,0,0,0,1,
	#         1,1,0,1,1,
	#         1,0,1,0,1,
	#         1,1,0,1,1,
	#         1,0,0,0,1,
	#         1,0,0,0,1,
	#         0,1,1,1,0,
	#     ])
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

	def clear_display
		@lines.clear
		i2cset(0, 0b00000001)
		sleep 2.16e-3
	end

	alias clear clear_display

	def return_home
		i2cset(0, 0b00000010)
		sleep 1.52e-3
	end

	# <tt>i_d</tt> :: [Integer] Increment or decrement
	#                           0 :: Decrement
	#                           1 :: Increment
	# <tt>s</tt>   :: [Integer] Shift entire display
	#                           0 :: Right
	#                           1 :: Left
	def entry_mode_set(i_d, s)
		i2cset(0, 0b00000100 | (i_d<<1) | (s))
		sleep 60e-6
	end

	# <tt>d</tt> :: [Integer] Set entire display on/off
	#                         0 :: Off
	#                         1 :: On
	# <tt>c</tt> :: [Integer] Cursor on/off
	#                         0 :: Off
	#                         1 :: On
	# <tt>b</tt> :: [Integer] Blink cursor
	#                         0 :: Off
	#                         1 :: On
	def display_on_off_control(d, c, b)
		i2cset(0, 0b00001000 | (d<<2) | (c<<1) | (b))
		sleep 60e-6
	end

	# <tt>s_c</tt> :: [Integer] Cursor or display
	#                           0 :: Cursor shift
	#                           1 :: Display shift
	# <tt>r_l</tt> :: [Integer] Direction
	#                           0 :: Left
	#                           1 :: Right
	def cursor_or_display_shift(s_c, r_l)
		i2cset(0, 0b00010000 | (s_c<<3) | (r_l<<2))
		sleep 60e-6
	end

	# <tt>dl</tt> :: [Integer] Data length
	#                          0 :: 4bit 
	#                          1 :: 8bit 
	# <tt>n</tt>  :: [Integer] Number of display lines
	#                          0 :: 1-line
	#                          1 :: 2-line
	# <tt>f</tt>  :: [Integer] Character font
	#                          0 :: Normal
	#                          1 :: Double font
	def function_set(dl, n, f)
		i2cset(0, 0b00100000 | (dl<<4) | (n<<3) | (f<<2))
		sleep 60e-6
	end

	# <tt>address</tt> :: [Integer] CGRAM address 6-bit
	def set_cgram_address(address)
		address = address & 0b00111111
		i2cset(0, 0b01000000 | address)
		sleep 60e-6
	end

	# <tt>address</tt> :: [Integer] DDRAM address 7-bit
	def set_ddram_address(address)
		address = address & 0b01111111
		i2cset(0, 0b10000000 | address)
		sleep 60e-6
	end

	# <tt>Returns</tt> :: [Hash] Result
	#                            :busy            :: [true | false] Busy flag
	#                            :address_counter :: [Integer] Current address count. 7-bit
	def read_busy_flag_and_address
		read = i2cget(0b01000000)
		{
			:busy => (read & 0b10000000) != 0,
			:address_counter => read & 0b01111111
		}
	end
end
