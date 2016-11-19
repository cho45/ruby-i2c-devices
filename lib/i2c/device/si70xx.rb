# coding: utf-8
class I2CDevice
  class SI70XX < I2CDevice

    ADDRESS = 0x40
    MEASURE_RH_HOLD = 0xE5
    MEASURE_TEMP_HOLD = 0xE3

    def self.address; ADDRESS; end
    def self.measure_rh_hold; MEASURE_RH_HOLD; end
    def self.measure_temp_hold; MEASURE_TEMP_HOLD; end


    def initialize(args={})
      args[:address] ||= self.class.address
      super args
      @rh_cmd = self.class.measure_rh_hold
      @tmp_cmd = self.class.measure_temp_hold
    end


    def relative_humidity
      ( (125 * measure(@rh_cmd)) / 65535 ) - 6
    end
    alias_method :rh, :relative_humidity


    def temp
      ( (175.72 * measure(@temp_cmd)) / 65536 ) - 46.85
    end

    private

      def measure(cmd)
        msb, lsb = i2cget(cmd, 2).unpack("C2")
        (msb << 8) + lsb
      end

  end
end
