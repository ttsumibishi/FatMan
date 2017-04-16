#!/usr/bin/ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'lib/config/config_reader'
require 'lib/config/configuration'
require 'lib/support/deep_struct'
require 'SSD1306'
require 'lib/display/ssd1306_handler'
require 'pi_piper'
require 'log4r'
require 'lib/support/mute'
require 'pi_piper'
require 'lib/net/access_point'
require 'lib/net/udp_sender'
require 'lib/gpio/pot'
include PiPiper

$logger = Log4r::Logger.new('logger')
console_outputter = Log4r::Outputter.stdout
console_outputter.formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %m")
$logger.outputters << console_outputter
$logger.info 'Starting blindies controller module...'

$logger.info 'Loading configuration...'
$config = Configuration.new('conf/config.yml')

$logger.info 'Initializing SSD1306...'
begin
  $display = SSD1306Handler.new
rescue => e
  $logger.error e
  $display = SSD1306Handler.new(true)
end


$logger.info 'Setting up ADC for MCP3008...'

clock = PiPiper::Pin.new(pin: 18, direction: :out)
adc_out = PiPiper::Pin.new(pin: 23)
adc_in = PiPiper::Pin.new(pin: 24, direction: :out)
cs = PiPiper::Pin.new(pin: 25, direction: :out)
pot_1 = 0
pot_2 = 1
pot_3 = 2
p1 = Pot.new(pot_1, clock, adc_out, adc_in, cs)
p2 = Pot.new(pot_2, clock, adc_out, adc_in, cs)
p3 = Pot.new(pot_3, clock, adc_out, adc_in, cs)

def status(params)
  sta = params[:sta]
  p1 = params[:pot_1]
  p2 = params[:pot_2]
  p3 = params[:pot_3]
  $display.display "  #{sta.to_s.rjust(2, '0')} | #{p1.to_s.rjust(3, '0')} #{p2.to_s.rjust(3, '0')} #{p3.to_s.rjust(3, '0')}\nMode: ON-CLICK\nBrightness\nSpeed\nDuty"
end


$led_power = Pin.new(pin: $config.pins.led.power, direction: :out)
$led_power.on
$led_ap = Pin.new(pin: $config.pins.led.ap, direction: :out)
if AccessPoint.enabled?
  $logger.info('Access Point is running and awaiting for connections')
  $led_ap.on
end

$led_data = Pin.new(pin: $config.pins.led.data, direction: :out)
$udp = UdpSender.new(broadcast: '192.168.1.255', activity_led: $led_data)


def shutdown
  puts 'Caught interrupt, cleanup'
  $led_power.off
  $led_ap.off
  puts 'Done with cleanup, exiting'
  exit
end

Signal.trap('INT') {
  shutdown
}

Signal.trap('TERM') {
  shutdown
}

after pin: 9, goes: :high do
  puts "PIN PRESSED!!!"
#  #p1, p2, p3 = read_pots
p1_val = p1.val
p2_val = p2.val
p3_val = p3.val
  $udp.send("0 #{p1_val} #{p2_val} #{p3_val}")
end

loop do
  #p1_val = p1.val
  #p2_val = p2.val
  #p3_val = p3.val

  #$logger.debug("P1: #{p1_val}, P2: #{p2_val}, P3: #{p3_val}")
end
loop do
  #p1 = normalize_pot(read_adc(pot_1, clock, adc_in, adc_out, cs))
  #p2 = normalize_pot(read_adc(pot_2, clock, adc_in, adc_out, cs))
  #p3 = normalize_pot(read_adc(pot_3, clock, adc_in, adc_out, cs))
  p1_val = p1.val
  p2_val = p2.val
  p3_val = p3.val
  sta = AccessPoint.stations
  $logger.debug("STA: #{sta}, P1: #{p1_val}, P2: #{p2_val}, P3: #{p3_val}")
  #$display.display("P1: #{p1}\nP2: #{p2}\nP3: #{p3}")
  status(pot_1: p1_val, pot_2: p2_val, pot_3: p3_val, sta: sta)
  #$udp.send("0 #{p1.val} #{p2.val} #{p3.val}")

  sleep 0.5
end


