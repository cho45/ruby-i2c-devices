require 'i2c'

# Implements the I2C-Device BMP085/BMP180
# This code was inspired by https://github.com/adafruit/Adafruit_Python_BMP
#
# Datasheet: https://www.adafruit.com/datasheets/BST-BMP180-DS000-09.pdf
#
# Currently this code was tested on a Banana Pi with a BMP185 device. It should work on a Raspberry or any other Linux with I2C-Dev
#
# ==Example
#   Using i2c-2 device (e.g. if you using a banana pi)
#
#   bmp = I2CDevice::Bmp180.new(driver: I2CDevice::Driver::I2CDev.new("/dev/i2c-2"), mode: 0)
#   puts "#{bmp.read_temperature / 10.0}°C"
#   sleep 1
#   puts "#{bmp.read_pressure / 100.0}hPa abs"
#   sleep 1
#   m_above_sealevel = 500 # position realtive to sealevel in m
#   puts "#{bmp.read_sealevel_pressure(m_above_sealevel) / 100.0}hPa rel"
#
class I2CDevice::Bmp180 < I2CDevice
    # BMP085 default address.
    BMP085_I2CADDR           = 0x77

    # Operating Modes
    BMP085_ULTRALOWPOWER     = 0
    BMP085_STANDARD          = 1
    BMP085_HIGHRES           = 2
    BMP085_ULTRAHIGHRES      = 3

    # BMP085 Registers
    BMP085_CAL_AC1           = 0xAA  # R   Calibration data (16 bits)
    BMP085_CAL_AC2           = 0xAC  # R   Calibration data (16 bits)
    BMP085_CAL_AC3           = 0xAE  # R   Calibration data (16 bits)
    BMP085_CAL_AC4           = 0xB0  # R   Calibration data (16 bits) unsigned
    BMP085_CAL_AC5           = 0xB2  # R   Calibration data (16 bits) unsigned
    BMP085_CAL_AC6           = 0xB4  # R   Calibration data (16 bits) unsigned
    BMP085_CAL_B1            = 0xB6  # R   Calibration data (16 bits)
    BMP085_CAL_B2            = 0xB8  # R   Calibration data (16 bits)
    BMP085_CAL_MB            = 0xBA  # R   Calibration data (16 bits)
    BMP085_CAL_MC            = 0xBC  # R   Calibration data (16 bits)
    BMP085_CAL_MD            = 0xBE  # R   Calibration data (16 bits)
    BMP085_CONTROL           = 0xF4
    BMP085_TEMPDATA          = 0xF6
    BMP085_PRESSUREDATA      = 0xF6

    # Commands
    BMP085_READTEMPCMD       = 0x2E
    BMP085_READPRESSURECMD   = 0x34

    # initialize the device and read the calibration registers
    #
    # ==params
    #  * args : hash defaults to {}
    #  ** :mode : one of BMP085_ULTRALOWPOWER | BMP085_STANDARD | BMP085_HIGHRES | BMP085_ULTRAHIGHRES defaults to BMP085_STANDARD see datasheet for more information
    #  ** :address : device address defaults to 0x77
    def initialize(args={})
        @mode = args.delete(:mode) || BMP085_STANDARD
        args = {
        address: BMP085_I2CADDR
        }.merge(args)

        super args

        raise "Mode must be between #{BMP085_ULTRALOWPOWER} and #{BMP085_ULTRAHIGHRES}" unless [BMP085_ULTRALOWPOWER, BMP085_STANDARD, BMP085_HIGHRES, BMP085_ULTRAHIGHRES].include?(@mode)

        calibration
    end

    # read the current real temperature in 0.1°C
    def read_temperature
        return calc_real_temperature(read_raw_temperature)
    end

    # read the current relative pressure in Pa
    def read_pressure
        return calc_real_pressure(read_raw_temperature, read_raw_pressure)
    end

    # Read current temperature and realtive pressure
    #
    # ==return
    #  * temperature in 0.1°C, pressure in Pa
    def read_temperature_and_pressure
        ut = read_raw_temperature
        up = read_raw_pressure

        return calc_real_temperature(ut), calc_real_pressure(ut, up)
    end

    # calculate the current pressure at sealevel from the current relative pressure and the gitven altitude
    #
    # ==params
    #  * altitude : curren altitude above sealevel in m defaults to 0
    def read_sealevel_pressure(altitude = 0.0)
        pressure = read_pressure()
        return cacl_sealevel_pressure(pressure, altitude)
    end

    # calculate the current pressure at sealevel from the given relative pressure and the gitven altitude
    #
    # ==params
    #  * altitude : curren altitude above sealevel in m
    #  * pressure : current relative pressure in Pa
    def cacl_sealevel_pressure(pressure, altitude)
        return pressure.to_f / ((1.0 - altitude.to_f / 44330.0) ** 5.255)
    end
    
    # get the calibration values
    #
    # ==return
    #  array of calibration data
    def get_cal
        return @cal_AC1, @cal_AC2, @cal_AC3, @cal_AC4, @cal_AC5, @cal_AC6, @cal_B1, @cal_B2, @cal_MB, @cal_MC, @cal_MD
    end

  private
    # read the current raw temperature value
    def read_raw_temperature
        i2cset(BMP085_CONTROL, BMP085_READTEMPCMD)
        sleep 0.005
        return i2cget(BMP085_TEMPDATA, 2).unpack('s>')[0]
    end

    # read the current raw pressure value
    def read_raw_pressure
        i2cset(BMP085_CONTROL, BMP085_READPRESSURECMD + (@mode << 6))

        if @mode == BMP085_ULTRALOWPOWER
        sleep 0.005
        elsif @mode == BMP085_HIGHRES
        sleep 0.014
        elsif @mode == BMP085_ULTRAHIGHRES
        sleep 0.026
        else
        sleep 0.008
        end

        sleep 1 # safety for testing

        msb, lsb, xlsb  = i2cget(BMP085_PRESSUREDATA, 3).unpack('C*')
        up  = ((msb << 16) + (lsb << 8) + xlsb) >> (8 - @mode)

        return up
    end

    # load the calibration registers into instance variables
    def calibration
        @cal_AC1, @cal_AC2, @cal_AC3, @cal_AC4, @cal_AC5, @cal_AC6, @cal_B1, @cal_B2,
            @cal_MB, @cal_MC, @cal_MD = i2cget(BMP085_CAL_AC1, 22).unpack('s>s>s>S>S>S>s>s>s>s>s>')
    end

    # calculate the read temperature using the calibration registers
    #
    # ==params
    #  * ut : raw templerature value
    # ==return
    #  true temperature in 0.1°C -> 150 = 15.0 °C
    def calc_real_temperature(ut)
        x1 = ((ut - @cal_AC6) * @cal_AC5)  / 2**15
        x2 = (@cal_MC * 2**11) / (x1 + @cal_MD)
        b5 = x1 + x2
        t = (b5 + 8) / 2**4

        return t
    end

    # calculate the read pressure using the calibration registers
    #
    # ==params
    #  * up : raw pressure value
    # ==return
    #  true pressure in Pa
    def calc_real_pressure(ut, up)
        x1 = ((ut - @cal_AC6) * @cal_AC5) / 2**15
        x2 = (@cal_MC * 2**11) / (x1 + @cal_MD)
        b5 = x1 + x2

        # Pressure Calculations
        b6 = b5 - 4000
        x1 = (@cal_B2 * (b6 * b6) / 2**12) / 2**11
        x2 = (@cal_AC2 * b6) / 2**11
        x3 = x1 + x2
        b3 = (((@cal_AC1 * 4 + x3) << @mode) + 2) / 4

        x1 = (@cal_AC3 * b6) / 2**13
        x2 = (@cal_B1 * ((b6 * b6) / 2**12)) / 2**16
        x3 = ((x1 + x2) + 2) / 2**2
        b4 = (@cal_AC4 * (x3 + 32768)) / 2**15

        b7 = (up - b3) * (50000 >> @mode)

        if b7 < 0x80000000
            pr = (b7 * 2) / b4
        else
            pr = (b7 / b4) * 2
        end

        x1 = (pr / 2**8) * (pr / 2**8)
        x1 = (x1 * 3038) / 2**16
        x2 = (-7357 * pr) / 2**16
        pr += ((x1 + x2 + 3791) / 2**4)

        return pr
    end

end 
