class I2CDevice
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

	attr_accessor :address

	def initialize(address, path="/dev/i2c-1")
		@path = path
		@address = address
	end

	def i2cget(address, length=1)
		i2c = File.open(@path, "r+")
		i2c.ioctl(I2C_SLAVE, @address)
		i2c.syswrite(address.chr)
		ret = i2c.read(length)
		i2c.close
		ret
	end

	def i2cset(*data)
		i2c = File.open(@path, "r+")
		i2c.ioctl(I2C_SLAVE, @address)
		i2c.syswrite(data.pack("C*"))
		i2c.close
	end
end

