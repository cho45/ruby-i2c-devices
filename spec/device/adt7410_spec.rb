#!rspec


$LOAD_PATH.unshift "lib"

require "tempfile"

require "i2c/device/adt7410"
require "i2c/mocki2cdevice"

describe ADT7410 do
	before do
		@mock = MockI2CDevice.new
		File.stub(:open) do
			@mock.open
		end
	end

	describe "#calculate_temperature" do
		context "16bit" do
			it "should treat positive fractial value" do
				# status
				@mock.memory[0x02] = 0b00000000
				# temp
				@mock.memory[0x00] = 0b00000000
				@mock.memory[0x01] = 0b00000001

				device = ADT7410.new(0x50, @mock.path)
				expect(device.read_configuration).to eq({
					:fault_queue      => 1,
					:ct_pin_polarity  => false,
					:int_pin_polarity => false,
					:int_ct_mode      => :interrupt_mode,
					:operation_mode   => :continuous_conversion,
					:resolution       => 16
				})
				expect(device.calculate_temperature).to eq(0.0078125)
			end

			it "should treat negative value" do
				# status
				@mock.memory[0x02] = 0b00000000
				# temp
				@mock.memory[0x00] = 0b10000000
				@mock.memory[0x01] = 0b00000000

				device = ADT7410.new(0x50, @mock.path)
				expect(device.calculate_temperature).to eq(-256)
			end
		end

		context "13bit" do
			it "should treat positive fractial value" do
				# status
				@mock.memory[0x02] = 0b00000000
				# temp
				@mock.memory[0x00] = 0b00000000
				@mock.memory[0x01] = 0b00001000

				device = ADT7410.new(0x50, @mock.path)
				device.configuration({
					resolution: 13,
				})

				expect(device.calculate_temperature).to eq(0.0625)
			end

			it "should treat negative value" do
				# status
				@mock.memory[0x02] = 0b00000000
				# temp
				@mock.memory[0x00] = 0b11100100
				@mock.memory[0x01] = 0b10000000

				device = ADT7410.new(0x50, @mock.path)
				device.configuration({
					resolution: 13,
				})

				expect(device.calculate_temperature).to eq(-55)
			end
		end
	end
end

