ruby-i2c-devices
================

i2c-devices is a library for using [I2C]( http://www.i2c-bus.org/ ) devices.

SYNOPSYS
========

Usage of I2CDevice class directly:

```
require "i2c"

device = I2CDevice.new(0x60, "/dev/i2c-0")

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

REQUIREMENTS
============

Currently this library depends on Linux's i2c-dev.

TODO
====

 * with GPIO
 * More supported devices
