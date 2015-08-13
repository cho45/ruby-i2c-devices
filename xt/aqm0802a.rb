# coding: utf-8

require "i2c/device/aqm0802"

aqm0802 = I2CDevice::AQM0802A.new
aqm0802.put_line(0, 'helloｫ')
aqm0802.put_line(1, ' world!')
