ruby-i2c-devices
================

i2c-devices is a library for using [I2C]( http://www.i2c-bus.org/ ) devices.

SYNOPSYS
========

Usage of I2CDevice class directly:

```
require "i2c"
require "i2c/driver/i2c-dev"
device = I2CDevice.new(address: 0x60, driver: I2CDevice::Driver::I2CDev.new("/dev/i2c-1"))

# like i2c-tools's i2cget command
length = 3
device.i2cget(0x01, length)

# like i2c-tools's i2cset command
device.i2cset(0x01, 0x11, 0x12 ... )

```

or pre-defiend device driver class:

```
require "i2c/device/acm1602ni"

lcd = I2CDevice::ACM1602NI.new

lcd.put_line(0, "0123456789ABCDEF")
```


with driver class

```
require "i2c/device/mpl115a2"
require "i2c/driver/i2c-dev"

mpl = I2CDevice::MPL115A2.new(driver: I2CDevice::Driver::I2CDev.new("/dev/i2c-0"))
p mpl.calculate_hPa
```

or GPIO backend driver (this is very slow)

```
require "i2c/device/mpl115a2"
require "i2c/driver/gpio"

mpl = I2CDevice::MPL115A2.new(driver: I2CDevice::Driver::GPIO.new(
	sda: 23, # pin 16 in raspberry pi
	scl: 24, # pin 18 in raspberry pi
))

p mpl.calculate_hPa

```

Class
=====

I2CDevice
---------

Generic class for manipulating I2C device.

### I2CDevice.new(address: address, driver: driver)

 * address : Integer : 7-bit slave address without r/w bit. MSB is always 0.
 * driver : I2CDevice::Driver : backend driver class. (default: I2CDevice::Driver::I2CDev)

### I2CDevice#i2cset(*data) #=> Integer

Write `data` to slave.

Returns `Integer` which is bytes length wrote.

### I2CDevice#i2cget(param, length=1) #=> String

This method read data from slave with following process:

 1. Write `param` to slave
 2. re-start
 3. Read data until NACK or `length`

Returns `String`.

I2CDevice::Driver::I2CDev
-------------------------

This depends on /dev/i2c-* (i2c-dev) feature on Linux. You may load i2c-dev kernel module.

### I2CDevice::Driver::I2CDev.new(path)

 * path : String : Path to /dev/i2c-*


I2CDevice::Driver::GPIO
-----------------------

This depends on /sys/class/gpio feature on Linux and implements by bit-banging.

### I2CDevice::Driver::I2CDev.new(sda: sda, scl: scl, speed: speed)

 * sda   : Integer : Pin number of SDA.
 * scl   : Integer : Pin number of SCL.
 * speed : Integer : I2C clock speed in kHz. (default: 1)

Pin number of `sda` and `scl` is not real pin number but logical pin number.
Eg. In Raspberry Pi, specifing `sda: 23, scl: 24` means using 16 and 18 pin.

You can specify 100 kHz or 400 kHz (or more) to `speed` but speed is rate-limited by host CPU speed.
Typically, this module fall short of requirements of I2C spec (in Raspberry Pi, clock speed is about 1.3kHz).
But most slave devices support DC~100kHz clock speed.

REQUIREMENTS
============

Currently this library depends on Linux's i2c-dev or sysfs with GPIO feature.

 * I2CDevice::Driver::I2CDev /dev/i2c-0 (i2c-dev), default
 * I2CDevice::Driver::GPIO /sys/class/gpio (GPIO)

TODO
====

 * More supported devices

