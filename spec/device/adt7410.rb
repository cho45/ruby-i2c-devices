#!rspec


$LOAD_PATH.unshift "lib"

require "tempfile"

require "i2c/device/adt7410"


describe ADT7410 do
	before do
		@i2cout = ""
		@i2cin  = []
		@ioctl  = nil

		ioctl = proc do |cmd, arg|
			@ioctl = [ cmd, arg ]
		end

		syswrite = proc do |str|
			@i2cout << str
		end

		sysread = proc do |n|
			@i2cin.shift
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

	describe "#calculate_temperature" do
		context "16bit" do
			it "should treat positive fractial value" do
				device = ADT7410.new(0x50, @temp.path)

				# status
				@i2cin << [
					0b10000000,
				].pack("C*")
					  
				# 16bit temp
				@i2cin << [
					0b00000000,
					0b00000001,
				].pack("C*")

				expect(device.calculate_temperature).to eq(0.0078125)
			end

			it "should treat negative value" do
				device = ADT7410.new(0x50, @temp.path)

				# status
				@i2cin << [
					0b10000000,
				].pack("C*")
					  
				# 16bit temp
				@i2cin << [
					0b10000000,
					0b00000000,
				].pack("C*")

				expect(device.calculate_temperature).to eq(-256)
			end
		end

		context "13bit" do
			it "should treat positive fractial value" do
				device = ADT7410.new(0x50, @temp.path)
				device.configuration({
					resolution: 13,
				})

				# status
				@i2cin << [
					0b10000000,
				].pack("C*")
					  
				# 13bit temp
				@i2cin << [
					0b00000000,
					0b00001000,
				].pack("C*")

				expect(device.calculate_temperature).to eq(0.0625)
			end

			it "should treat negative value" do
				device = ADT7410.new(0x50, @temp.path)
				device.configuration({
					resolution: 13,
				})

				# status
				@i2cin << [
					0b10000000,
				].pack("C*")
					  
				# 13bit temp
				@i2cin << [
					0b11100100,
					0b10000000,
				].pack("C*")

				expect(device.calculate_temperature).to eq(-55)
			end
		end
	end
end

