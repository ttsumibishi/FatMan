class SSD1306Handler
  module Constants
    FONT_SIZE = 1
    COLS = 21
    LINES = 8
  end

  def initialize(error = false)
    if error
      @disp = Mute
    else
      @disp = SSD1306::Display.new(protocol: :i2c,
                                   path: '/dev/i2c-1',
                                   address: 0x3C,
                                   width: 128,
                                   height: 64)
      @disp.font_size = Constants::FONT_SIZE
    end
  rescue Errno::EIO => e
    raise 'No SSD1306 found.'
  end

  def display(string)
    clear
    @disp.clear
    @disp.println string
    @disp.display!
  end

  def char(string)
    @disp.print string
    @disp.display!
  end

  def clear
    @disp.clear
  end

end
