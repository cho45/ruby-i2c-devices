
require "i2c"

class MPL115A2 < I2CDevice
	def initialize(args)
		args[:address] = 0x60
		super
		coefficient = i2cget(0x04, 8).unpack("n*")

		@a0  = fixed_point(coefficient[0], 12)
		@b1  = fixed_point(coefficient[1], 2)
		@b2  = fixed_point(coefficient[2], 1)
		@c12 = fixed_point(coefficient[3], 0) / (1<<9)
	end

	def fixed_point(fixed, int_bits)
		msb = 15
		deno = (1<<(msb-int_bits)).to_f
		if (fixed & (1<<15)).zero?
			fixed / deno
		else
			-( ( (~fixed & 0xffff) + 1) / deno )
		end
	end

	def calculate_hPa
		i2cset(0x12, 0x01) # CONVERT

		sleep 0.003

		data = i2cget(0x00, 4).unpack("n*")

		p_adc = (data[0]) >> 6
		t_adc = (data[1]) >> 6

		p_comp = @a0 + (@b1 + @c12 * t_adc) * p_adc + @b2 * t_adc
		hPa = p_comp * ( (1150 - 500) / 1023.0) + 500;
	end
end
