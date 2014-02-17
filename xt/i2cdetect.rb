#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "optparse"

require "i2c"
require "i2c/driver/i2c-dev"
require "i2c/driver/gpio"

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

i2c_devices = Dir.glob("/dev/i2c-*")
is_gpio_supported = Dir.glob("/sys/class/gpio")

driver = nil

OptionParser.new do |opt|
	opt.banner = <<-EOB.gsub(/^\t+/, "")  
		Usage: #{$0} [opts]
	EOB

	opt.separator ""
	opt.separator "Options:" 
	opt.on("-d BACKEND", "--driver BACKEND", [ i2c_devices.empty?? "" : "i2cdev,[path]", is_gpio_supported ? "gpio,[sda pin],[scl pin]" : "" ].join("\t")) do |backend|
		backend = backend.split(/,/)
		case backend.shift
		when "i2cdev"
			driver = I2CDevice::Driver::I2CDev.new(backend.shift)
		when "gpio"
			driver = I2CDevice::Driver::GPIO.new(sda: backend[0], scl: backend[1])
		end
	end
	i2c_devices.each do |path|
		opt.separator "\t\t\t--backend i2cdev,#{path}" 
	end
	opt.separator "\t\t\t--backend gpio,23,24" 

	opt.parse!(ARGV)
end

puts "Using %p" % driver if driver

puts "% 2s  %s" % ["", 16.times.map {|n| "% 2x" % n }.join(" ") ]
8.times do |high|
	puts "%02x: %s" % [ high << 4, 16.times.map {|low|
		a = high << 4 | low
		if (a >> 3) == 0b1111 || (a >> 3) == 0b0000
			"  "
		else
			d = I2CDevice.new(address: a, driver: driver)
			begin
				d.i2cset(0x00)
				"%02x" % a
			rescue I2CDevice::I2CIOError => e
				"--"
			end
		end
	}.join(" ") ]
end
