
require 'i2c/device/hdc1000'
require 'pp'

hdc = I2CDevice::HDC1000.new
pp hdc.get_data
