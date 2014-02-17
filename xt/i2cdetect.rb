#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "i2c"
require "i2c/driver/i2c-dev"

# Address List
# .... ... r/w
# 0000 000   0 -> general call address
# 0000 000   1 -> start byte
# 0000 001   x -> cbus address
# 0000 010   x -> reserved for other protocols
# 0000 011   x -> reserved for future
# 0000 1xx   x -> Hs-mod master code
# 1111 1xx   x -> device id
# 1111 0xx   x -> 10-bit addressing

puts "% 2s  %s" % ["", 16.times.map {|n| "% 2x" % n }.join(" ") ]
8.times do |high|
	puts "%02x: %s" % [ high << 4, 16.times.map {|low|
		a = high << 4 | low
		if (a >> 3) == 0b1111 || (a >> 3) == 0b0000
			"  "
		else
			d = I2CDevice.new(address: a, driver: I2CDevice::Driver::I2CDev.new("/dev/i2c-1"))
			begin
				d.i2cset(0x00)
				"%02x" % a
			rescue I2CDevice::I2CIOError => e
				"--"
			end
		end
	}.join(" ") ]
end
