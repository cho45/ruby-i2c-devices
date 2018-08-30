#!/usr/bin/env ruby

$LOAD_PATH << "lib"
require "i2c"
require "i2c/driver/i2c-dev"
require "i2c/device/bme280"

@device = I2CDevice::Bme280.new(driver: I2CDevice::Driver::I2CDev.new("/dev/i2c-1"))
p @device.read_id
p @device
@device.write_config(I2CDevice::Bme280::T_STANDBY_0_5MS, I2CDevice::Bme280::FILTER_16)
@device.write_ctrl_hum(I2CDevice::Bme280::OVERSAMPLE_1)
@device.write_ctrl_meas(I2CDevice::Bme280::OVERSAMPLE_16, I2CDevice::Bme280::OVERSAMPLE_2, I2CDevice::Bme280::MODE_NORMAL)
p @device.calc_sensor_data

