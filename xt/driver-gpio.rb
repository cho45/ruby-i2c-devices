#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "i2c/device/mpl115a2"
require "i2c/driver/gpio"

mpl = MPL115A2.new(driver: I2CDevice::Driver::GPIO.new(
	sda: 23, # pin 16 in raspberry pi
	scl: 24, # pin 18 in raspberry pi
))

loop do
	p mpl.calculate_hPa
end

