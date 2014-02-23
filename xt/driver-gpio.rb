#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "i2c/device/mpl115a2"
require "i2c/driver/gpio"

# I2CDevice::Driver::GPIO.class_variable_set(:@@DEBUG, true)

driver = I2CDevice::Driver::GPIO.new(
	sda: 23, # pin 16 in raspberry pi
	scl: 24, # pin 18 in raspberry pi
)


#device = I2CDevice.new(address: 0x20, driver: driver)
#loop do
#	seq = Array.new(8) { rand(0x10) }
#	seq = (0..7).map {|n| 0x10 + n }
#	seq = (1..10).to_a
#	p seq
#	p device.i2cset(0x00, *seq)
#	# p device.i2cget(0x00, 8).unpack("C*")
#
#	exit 1
#	sleep 1
#end

mpl = I2CDevice::MPL115A2.new(driver: driver)
loop do
	p mpl.calculate_hPa
	sleep 1
end

