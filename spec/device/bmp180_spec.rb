#!rspec

$LOAD_PATH.unshift "lib"

require "tempfile"

require "i2c/device/bmp180"
require "i2c/driver/i2c-dev"
require "spec/mocki2cdevice"

describe I2CDevice::Bmp180 do
	before do
		@mock = MockI2CDevice.new
		allow(File).to receive(:open) do
			@mock.open
		end
		
		(0x00..0xFF).each do |i|
		   @mock.memory[i] =0x00
		end

		# Write example calibration data from datasheet
		@mock.memory[0xAA] = 0x01
		@mock.memory[0xAB] = 0x98
		@mock.memory[0xAC] = 0xFF
		@mock.memory[0xAD] = 0xB8
		@mock.memory[0xAE] = 0xC7
		@mock.memory[0xAF] = 0xD1
		@mock.memory[0xB0] = 0x7F
		@mock.memory[0xB1] = 0xE5
		@mock.memory[0xB2] = 0x7F
		@mock.memory[0xB3] = 0xF5
		@mock.memory[0xB4] = 0x5A
		@mock.memory[0xB5] = 0x71
		@mock.memory[0xB6] = 0x18
		@mock.memory[0xB7] = 0x2E
		@mock.memory[0xB8] = 0x00
		@mock.memory[0xB9] = 0x04
		@mock.memory[0xBA] = 0x80
		@mock.memory[0xBB] = 0x01
		@mock.memory[0xBC] = 0xDD
		@mock.memory[0xBD] = 0XF9
		@mock.memory[0xBE] = 0x0B
		@mock.memory[0xBF] = 0x34
		
		@driver = I2CDevice::Driver::I2CDev.new(@mock.path)
	end
	
	describe "do read and calculate temperature" do
		it "should reand and calculate temperature" do
			bmp = I2CDevice::Bmp180.new(driver: @driver)
			expect(bmp.get_cal).to eq([408, -72, -14383, 32741, 32757, 23153, 6190, 4, -32767, -8711, 2868])
			@mock.memory[0xF6] = 0x6C
			@mock.memory[0xF7] = 0xFA
			
			expect(bmp.read_temperature).to eq(150) # Temperature 0.1C -> 15.0C
			expect(@mock.memory[0XF4]).to eq(0x2E)
		end
	end
	
	describe "do read and calculate pressure" do
		it "should reand and calculate pressure" do
			bmp = I2CDevice::Bmp180.new(driver: @driver)
			expect(bmp.get_cal).to eq([408, -72, -14383, 32741, 32757, 23153, 6190, 4, -32767, -8711, 2868])
			@mock.memory[0xF6] = 0x5D
			@mock.memory[0xF7] = 0x33

			# expect(bmp.read_pressure).to eq(69964) # datasheet test at 15.0C
			
			# Using 0x5D, 0x33 as temp and pressure -> 63524Pa at -26.8C
			expect(bmp.read_pressure).to eq(63524) # pressure in Pa
			expect(@mock.memory[0xF4]).to eq(0x74) # 0x34 + (mode << 6) with mode = 1
		end
	end

	describe "do read and calculate relative pressure" do
		it "should reand and calculate relative pressure" do
			bmp = I2CDevice::Bmp180.new(driver: @driver)
			expect(bmp.get_cal).to eq([408, -72, -14383, 32741, 32757, 23153, 6190, 4, -32767, -8711, 2868])
			@mock.memory[0xF6] = 0x5D
			@mock.memory[0xF7] = 0x33

			# at sea level
			expect(bmp.read_sealevel_pressure(0)).to eq(63524) # pressure in Pa
			# at 500m above sea level
			expect(bmp.read_sealevel_pressure(500).to_i).to eq(67425) # pressure in Pa
		end
	end
	
end
