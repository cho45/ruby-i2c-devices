# coding: utf-8

require "i2c"

class ADT7410 < I2CDevice
	OPERATION_MODE = {
		0b00 => :continuous_conversion,
		0b01 => :one_shot,
		0b10 => :one_sps_mode,
		0b11 => :shutdown,
	}

	INT_CT_MODE = {
		0 => :interrupt_mode,  
		1 => :comparator_mode,
	}

	RESOLUTION = {
		0 => 13,
		1 => 16,
	}

	attr_reader :configuration

	def initialize(address, path)
		super
		configuration({})
	end

	def calculate_temperature
		while read_status[:RDY]
			case @configuration[:operation_mode]
			when :continuous_conversion
				sleep 60e-3
			when :one_shop
				sleep 240e-3
			when :one_sps_mode
				sleep 60e-3
			when :shutdown
				raise "shutdown"
			end
		end

		data = i2cget(0x00, 2).unpack("C*")
		temp = data[0] << 8 | data[1]

		case @configuration[:resolution]
		when 16
			if temp[15] == 1
				temp = (temp - 65536) / 128.0
			else
				temp = temp / 128.0
			end
		when 13
			flags = temp & 0b111
			temp = temp >> 3
			if temp[12] == 1
				temp = (temp - 8192) / 16.0
			else
				temp = temp / 16.0
			end
		end
	end

	def read_status
		status = i2cget(0x02).unpack("C")
		{
			T_low:  status[4] == 1,
			T_high: status[5] == 1,
			T_crit: status[6] == 1,
			RDY:    status[7] == 1,
		}
	end

	def read_id
		id = i2cget(0x0b).unpack("C")
		{
			revision_id:    id * 0b111,
			manufacture_id: id >> 2,
		}
	end

	def software_reset
		i2cset(0x2f, 0x01)
	end

	def configuration(args)
		args = {
			fault_queue:      1,
			ct_pin_polarity:  0,
			int_pin_polarity: 0,
			int_ct_mode:      :interrupt_mode,
			operation_mode:   :continuous_conversion,
			resolution:       16,
		}.merge(args)

		@configuration = args

		conf = 
			RESOLUTION.key(args[:resolution]) << 7 |
			OPERATION_MODE.key(args[:operation_mode]) << 5 |
			INT_CT_MODE.key(args[:int_ct_mode]) << 4 |
			args[:int_pin_polarity] << 3 |
			args[:ct_pin_polarity] << 2 |
			args[:fault_queue] - 1

		i2cset(0x03, conf)
	end

	def read_configuration
		conf = i2cget(0x03).unpack("C")
		{
			fault_queue:      (conf & 0b11) + 1,
			ct_pin_polarity:  conf[2] == 1,
			int_pin_polarity: conf[3] == 1,
			int_ct_mode:      INT_CT_MODE[conf[4]],
			operation_mode:   OPERATION_MODE[(conf & 0b01100000) >> 5],
			resolution:       RESOLUTION[conf[7]],
		}
	end

	def set_T_high(value)
		set_point(0x04, value)
	end

	def set_T_low(value)
		set_point(0x06, value)
	end

	def set_T_crit(value)
		set_point(0x08, value)
	end

	def set_T_hyst(value)
		i2cset(0x0a, value)
	end

	private
	def set_point(address, value)
		v = value * 128
		i2cset(address, v >> 8, v & 0xff)
	end
end



