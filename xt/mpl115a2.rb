#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "i2c/device/mpl115a2"

mpl = I2CDevice::MPL115A2.new

loop do
	p mpl.calculate_hPa
end

