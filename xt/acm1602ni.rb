#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "i2c/device/acm1602ni"

lcd = ACM1602NI.new

lcd.define_character(0, [
	1,0,1,0,1,
	1,0,1,0,1,
	1,0,1,0,1,
	1,0,1,0,1,
	1,0,1,0,1,
	1,0,1,0,1,
	1,0,1,0,1,
	1,0,1,0,1,
])

lcd.put_line(0, "1234567890abcdef")
lcd.put_line(1, "\x00" * 16)

