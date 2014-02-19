
require "i2c"
require "i2c/driver"

module I2CDevice::Driver
	class I2CDev < Base
		# ioctl command
		# Ref. https://www.kernel.org/pub/linux/kernel/people/marcelo/linux-2.4/include/linux/i2c.h
		I2C_RETRIES     = 0x0701
		I2C_TIMEOUT     = 0x0702
		I2C_SLAVE       = 0x0703
		I2C_SLAVE_FORCE = 0x0706
		I2C_TENBIT      = 0x0704
		I2C_FUNCS       = 0x0705
		I2C_RDWR        = 0x0707
		I2C_SMBUS       = 0x0720
		I2C_UDELAY      = 0x0705
		I2C_MDELAY      = 0x0706

		def initialize(path=nil)
			if path.nil?
				path = Dir.glob("/dev/i2c-*").sort.last
			end

			unless File.exist?(path)
				raise I2CDevice::I2CIOError, "/dev/i2c-0 is required"
			end

			@path = path
		end

		def i2cget(address, param, length)
			i2c = File.open(@path, "r+")
			i2c.ioctl(I2C_SLAVE, address)
			i2c.syswrite(param.chr)
			ret = i2c.sysread(length)
			i2c.close
			ret
		rescue Errno::EIO => e
			raise I2CDevice::I2CIOError, e.message
		end

		def i2cset(address, *data)
			i2c = File.open(@path, "r+")
			i2c.ioctl(I2C_SLAVE, address)
			i2c.syswrite(data.pack("C*"))
			i2c.close
		rescue Errno::EIO => e
			raise I2CDevice::I2CIOError, e.message
		end
	end
end


