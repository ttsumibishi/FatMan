class Pot

  def initialize(pin, clock, adc_out, adc_in, cs)
    @pin = pin
    @clock = clock
    @adc_out = adc_out
    @adc_in = adc_in
    @cs = cs
    @prev = self.val
  end

  def val
    raw = read_adc(@pin, @clock, @adc_in, @adc_out, @cs)
    norm = normalize(raw)
    return @prev if norm > 255
    @prev = norm
    #puts "POT RAW: #{raw} NORM: #{norm}"
    return norm
    return normalize(read_adc(@pin, @clock, @adc_in, @adc_out, @cs))
  end

  private

  def read_adc(adc_pin, clockpin, adc_in, adc_out, cspin)
    cspin.on
    clockpin.off
    cspin.off

    command_out = adc_pin
    command_out |= 0x18
    command_out <<= 3

    (0..4).each do
      adc_in.update_value((command_out & 0x80) > 0)
      command_out <<= 1
      clockpin.on
      clockpin.off
    end
    result = 0

    (0..11).each do
      clockpin.on
      clockpin.off
      result <<= 1
      adc_out.read
      if adc_out.on?
        result |= 0x1
      end
    end

    cspin.on

    result >> 1
  end

  def normalize(v)
    return (v / 4)
  end
end