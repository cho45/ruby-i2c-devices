
require "i2c"

class I2CDevice::GridEYE < I2CDevice
	POWER_CONTROL_REGISTER = 0x00
	POWER_CONTROL_NORMAL_MODE = 0x00
	POWER_CONTROL_SLEEP_MODE = 0x10
	POWER_CONTROL_STAND_BY_MODE_60SEC = 0x20
	POWER_CONTROL_STAND_BY_MODE_10SEC = 0x21

	RESET_REGISTER = 0x01
	RESET_FLAG_RESET = 0x30
	RESET_INITIAL_RESET = 0x3F

	FRAME_RATE_REGISTER = 0x02
	FRAME_RATE_1FPS = 0x01
	FRAME_RATE_10FPS = 0x00

	INTERRUPT_CONTROL_REGISTER = 0x03
	INTERRUPT_CONTROL_INTMOD_Pos = 1
	INTERRUPT_CONTROL_INTMOD_ABSOLUTE_VALUE = 1
	INTERRUPT_CONTROL_INTMOD_DIFFERENCE_VALUE = 0
	INTERRUPT_CONTROL_INTEN_Pos = 0
	INTERRUPT_CONTROL_INTEN_ACTIVE = 1
	INTERRUPT_CONTROL_INTEN_REACTIVE = 0

	STATUS_REGISTER = 0x04
	STATUS_OVF_THS_Pos = 3
	STATUS_OVF_IRS_Pos = 2
	STATUS_OVF_INTF = 1

	STATUS_CLEAR_REGISTER = 0x05
	STATUS_CLEAR_OVT_CLR_Pos = 3
	STATUS_CLEAR_OVS_CLR_Pos = 2
	STATUS_CLEAR_INTCLR = 1

	AVERAGE_REGISTER = 0x07
	AVERAGE_MAMOD_Pos = 5

	INTERRUPT_LEVEL_REGISTER = 0x08

	THERMISTOR_REGISTOR = 0x0E

	INTERRUPT_TABLE_REGISTER = 0x10

	TEMPERATURE_REGISTER = 0x80

	def initialize(args={})
		args[:address] = 0x68
		super
	end

	def fixed_point(fixed, int_bits)
		msb = 11
		deno = (1<<(msb-int_bits)).to_f
		if (fixed & (1<<11)).zero?
			fixed / deno
		else
			-( ( (~fixed & 0xffff) + 1) / deno )
		end
	end

	def set_frame_rate(fps)
		value =
			case fps
			when 1
				FRAME_RATE_1FPS
			when 10
				FRAME_RATE_10FPS
			else
				raise "Invalid FPS value"
			end
		i2cset(FRAME_RATE_REGISTER, value)
	end

	def set_average_mode(average)
		i2cset(0x1f, 0x50)
		i2cset(0x1f, 0x45)
		i2cset(0x1f, 0x57)
		i2cset(AVERAGE_REGISTER, average ? 0x20 : 0x00)
		i2cset(0x1f, 0x00)
	end

	def power_control(mode)
		i2cset(POWER_CONTROL_REGISTER, mode)
	end

	def initial_reset
		i2cset(RESET_REGISTER, RESET_INITIAL_RESET)
	end

	def flag_reset
		i2cset(RESET_REGISTER, RESET_FLAG_RESET)
	end

	def read_thermistor
		t = i2cget(THERMISTOR_REGISTOR, 2).unpack("v*")[0]
		fixed_point(t, 7)
	end

	def read_pixels
		i2cget(TEMPERATURE_REGISTER, 64*2).unpack("v*").map {|t|
			fixed_point(t, 9)
		}.each_slice(8).to_a
	end
end


