# coding: utf-8

require "i2c"

# http://www.ti.com/product/HDC1000
# A Digital humidity/temperature sensor

class I2CDevice::HDC1000 < I2CDevice
	def initialize(args = {})
		args = {
			address: 0x40
		}.merge(args)
		super args
		configuration
	end

	def configuration
		i2cset(
			0x02, # Configuration register
			0x10, # TRES 14bit
			0x00  # HRES 14bit
		)
	end

	def get_data
		i2cset(0x00)
		sleep 6.35e-3 + 6.5e-3
		raw = i2cget(nil, 4).unpack("C4")
		{
			temperature: calc_temperature(raw[0], raw[1]),
			humidity: calc_humidity(raw[2], raw[3])
		}
	end

	def calc_temperature(d1, d2)
	  ((d1<<8 | d2).to_f / 2**16 * 165) - 40
	end

	def calc_humidity(d1, d2)
	  (d1<<8 | d2).to_f / 2**16 * 100
	end
end
