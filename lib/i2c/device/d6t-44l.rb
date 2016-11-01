#!/usr/bin/env ruby


class I2CDevice::D6T44L < I2CDevice
	class InvalidParityException < Exception; end

	def initialize(args={})
		args[:address] = 0x0a
		super
	end

	def read_data
		data = i2cget(0x4c, 35)
		unless checkPEC(data, false)
			raise InvalidParityException
		end

		# PTAT はセンサ内部の参照温度データ
		ptat, *pixels = data[0..-2].unpack("v*")
		{
			:PTAT => ptat,
			:PIXELS => pixels.each_slice(4).to_a
		}
	end

	private
	def calc_crc(data)
		8.times do
			tmp = data
			data = (data << 1) & 0xff
			if tmp & 0x80 != 0
				data ^= 0x07
			end
		end
		data
	end

	def checkPEC(data, userr=true)
		crc = 0
		if userr
			crc = calc_crc(0x14)
			crc = calc_crc(0x4c ^ crc)
			crc = calc_crc(0x15 ^ crc)
		else
			crc = calc_crc(0x15)
		end
		(data.size - 1).times do |i|
			crc = calc_crc(data[i].ord ^ crc)
		end
		data[data.size-1].ord == crc
	end
end
