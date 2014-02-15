#!rspec


$LOAD_PATH.unshift "lib"

require "tempfile"

require "i2c/device/hd44780"


describe HD44780 do
	before do
		@i2cout = ""
		@i2cin  = ""
		@ioctl  = nil

		ioctl = proc do |cmd, arg|
			@ioctl = [ cmd, arg ]
		end

		syswrite = proc do |str|
			@i2cout << str
		end

		sysread = proc do |n|
			@i2cin
		end

		@temp = Tempfile.new("i2c")
		file = nil
		open = File.method(:open)
		File.stub(:open) do
			file = open.call(@temp.path, "r+")
			file.define_singleton_method(:ioctl) {|cmd,arg| ioctl.call(ioctl) }
			file.define_singleton_method(:syswrite) {|str| syswrite.call(str) }
			file.define_singleton_method(:sysread) {|n| sysread.call(n) }
			file
		end
	end

	describe "#initialize_lcd" do
		it "should initialize lcd" do
			lcd = HD44780.new(0x10, @temp.path)

			expect(@i2cout.unpack("C*")).to eq([
				0b00000000,
				0b00111000,
				0b00000000,
				0b00111000,
				0b00000000,
				0b00111000,
				0b00000000,
				0b00111000,
				0b00000000,
				0b00001100,
				0b00000000,
				0b00000001,
			])
		end
	end

	describe "#put_line" do
		it "should be put_line 1/2" do
			lcd = HD44780.new(0x10, @temp.path)

			@i2cout.clear

			lcd.put_line(0, "0123456789abcdef")

			expect(@i2cout.unpack("C*")).to eq([
				# set_ddram_address
				0b00000000, 0b10000000,

				# write commands
				0b10000000, "0".ord,
				0b10000000, "1".ord,
				0b10000000, "2".ord,
				0b10000000, "3".ord,
				0b10000000, "4".ord,
				0b10000000, "5".ord,
				0b10000000, "6".ord,
				0b10000000, "7".ord,
				0b10000000, "8".ord,
				0b10000000, "9".ord,
				0b10000000, "a".ord,
				0b10000000, "b".ord,
				0b10000000, "c".ord,
				0b10000000, "d".ord,
				0b10000000, "e".ord,
				0b10000000, "f".ord,
			])

			@i2cout.clear

			lcd.put_line(1, "0123456789abcdef")

			expect(@i2cout.unpack("C*")).to eq([
				# set_ddram_address
				0b00000000, 0b11000000,

				# write commands
				0b10000000, "0".ord,
				0b10000000, "1".ord,
				0b10000000, "2".ord,
				0b10000000, "3".ord,
				0b10000000, "4".ord,
				0b10000000, "5".ord,
				0b10000000, "6".ord,
				0b10000000, "7".ord,
				0b10000000, "8".ord,
				0b10000000, "9".ord,
				0b10000000, "a".ord,
				0b10000000, "b".ord,
				0b10000000, "c".ord,
				0b10000000, "d".ord,
				0b10000000, "e".ord,
				0b10000000, "f".ord,
			])
		end
	end

	describe "#define_character" do
		it "should define character" do
			lcd = HD44780.new(0x10, @temp.path)

			@i2cout.clear

			lcd.define_character(0, [
				0,1,1,1,0,
				1,0,0,0,1,
				1,1,0,1,1,
				1,0,1,0,1,
				1,1,0,1,1,
				1,0,0,0,1,
				1,0,0,0,1,
				0,1,1,1,0,
			])

			expect(@i2cout.unpack("C*")).to eq([
				# set_cgram_address
				0b00000000, 0b01000000,

				0b10000000, 0b00001110,
				0b10000000, 0b00010001,
				0b10000000, 0b00011011,
				0b10000000, 0b00010101,
				0b10000000, 0b00011011,
				0b10000000, 0b00010001,
				0b10000000, 0b00010001,
				0b10000000, 0b00001110,
			])
		end
	end
end
