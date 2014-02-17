ruby-i2c-devices
================

i2c-devices is a library for using [I2C]( http://www.i2c-bus.org/ ) devices.

SYNOPSYS
========

Usage of I2CDevice class directly:

```
require "i2c"

device = I2CDevice.new(address: 0x60, driver: I2CDevice::Driver::I2CDev.new("/dev/i2c-1"))

# like i2c-tools's i2cget command
device.i2cget(0x01)

# like i2c-tools's i2cset command
device.i2cset(0x01, 0x11, 0x12 ... )

```

or pre-defiend device driver class:

```
require "i2c/device/acm1602ni"

lcd = ACM1602NI.new

lcd.put_line(0, "0123456789ABCDEF")
```


with driver class

```
require "i2c/device/mpl115a2"
require "i2c/driver/i2c-dev"

mpl = MPL115A2.new(driver: I2CDevice::Driver::I2CDev.new("/dev/i2c-0"))
p mpl.calculate_hPa
```

or GPIO backend driver (this is very slow)

```
require "i2c/device/mpl115a2"
require "i2c/driver/gpio"

mpl = MPL115A2.new(driver: I2CDevice::Driver::GPIO.new(
	sda: 23, # pin 16 in raspberry pi
	scl: 24, # pin 18 in raspberry pi
))

p mpl.calculate_hPa

```

REQUIREMENTS
============

Currently this library depends on Linux's i2c-dev or sysfs with GPIO.

TODO
====

 * More supported devices
