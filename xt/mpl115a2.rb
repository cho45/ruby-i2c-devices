#!/usr/bin/env ruby

$LOAD_PATH.unshift "lib"

require "i2c/device/mpl115a2"

mpl = MPL115A2.new

p mpl.calculate_hPa

