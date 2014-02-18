#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "i2c/device/mpl115a2"
require "i2c/driver/gpio"

# I2CDevice::Driver::GPIO.class_variable_set(:@@DEBUG, true)

driver = I2CDevice::Driver::GPIO.new(
	sda: 23, # pin 16 in raspberry pi
	scl: 24, # pin 18 in raspberry pi
)


device = I2CDevice.new(address: 0x65, driver: driver)
p device.i2cset(0x00, 0x01, 0x02)
p device.i2cget(0x00, 2)

mpl = MPL115A2.new(driver: driver)
loop do
	p mpl.calculate_hPa
	sleep 1
end

