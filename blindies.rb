#!/usr/bin/ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'log4r'
require 'pi_piper'
require 'pp'
require 'SSD1306'
include PiPiper

require 'lib/config/config_reader'
require 'lib/config/configuration'
require 'lib/display/ssd1306_handler'
require 'lib/mode'
require 'lib/net/access_point'
require 'lib/net/udp_sender'
require 'lib/support/deep_struct'
require 'lib/support/mute'

`/home/lmdracos/blindies/cleanup.sh`
$continuous = false
$increment = 30
$logger = Log4r::Logger.new('logger')
console_outputter = Log4r::Outputter.stdout
console_outputter.formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %m")
$logger.outputters << console_outputter
$logger.info 'Starting blindies controller module...'
$logger.level = Log4r::DEBUG

$logger.info 'Loading configuration...'
$config = Configuration.new('conf/config.yml')

$logger.info 'Configuring LEDs...'
$led_power = Pin.new(pin: $config.pins.led.power, direction: :out)
$led_power.on
$led_ap = Pin.new(pin: $config.pins.led.ap, direction: :out)
$led_data = Pin.new(pin: $config.pins.led.data, direction: :out)

$leds = [$led_power, $led_ap, $led_data]

if AccessPoint.enabled?
  $logger.info('Access Point is running and awaiting for connections')
  $led_ap.on
end

$logger.info 'Initializing SSD1306...'
begin
  $display = SSD1306Handler.new
rescue => e
  $logger.error e
  $display = SSD1306Handler.new(true)
end

def clear
  $display.clear
end

def status(params)
  sta = params[:sta]
  p1 = $current_p1 #params[:p1]
  p2 = $current_p2 #params[:p2]
  p3 = $current_p3 #params[:p3]
  new_mode = params[:new_mode]
  string = []
  string << "  #{sta.to_s.rjust(2, '0')} | #{p1.to_s.rjust(3, '0')} #{p2.to_s.rjust(3, '0')} #{p3.to_s.rjust(3, '0')}"
  string << "Pattern: #{$current_mode.name[0..11]}"
  string << "Mode: #{$continuous ? 'Continuous' : 'On Send'}"
  string << "#{"%03d" % $p1} #{$current_mode.p1}" if $current_mode.p1
  string << "#{"%03d" % $p2} #{$current_mode.p2}" if $current_mode.p2
  string << "#{"%03d" % $p3} #{$current_mode.p3}" if $current_mode.p3
  if !new_mode.nil? && $current_mode != new_mode
    string << "New Mode: #{new_mode.name[0..10]}"
  end
  $display.display string.join("\n")
end

$logger.info 'Configuring modes...'
$modes = []
$config.modes.to_h.each_pair do |name, mode|
  sliders = $config.modes.send(name.to_sym).sliders
  if mode['enabled'] == 1
    $logger.info "   + #{mode['name']}"
    $modes << Mode.new(name: mode['name'],
                       val: mode['val'],
                       p1: sliders.s1,
                       p2: sliders.s2,
                       p3: sliders.s3)
  end
end

$current_p1 = 0
$current_p2 = 0
$current_p3 = 0
$current_mode_num = 0
$current_mode = $modes[$current_mode_num]

$logger.info "Setting initial mode to #{$current_mode.name}"
status(sta: AccessPoint.stations)

$p1 = 0
$p2 = 0
$p3 = 0
$mode_num = $current_mode_num
$mode = $current_mode

$logger.info 'Configuring UDP sender...'
$udp = UdpSender.new(broadcast: '192.168.1.255', activity_led: $led_data)

def netsend
  $udp.send("#{$current_mode.val} #{$current_p1} #{$current_p2} #{$current_p3}")
end

def shutdown
  puts 'Caught interrupt, cleanup'

  puts 'Turning off Blindies'
  $current_mode_num = 0 # TODO - Store all off somewhere in the config
  $current_mode = $modes[$current_mode_num]
  $current_p1 = 0
  $current_p2 = 0
  $current_p3 = 0
  $continuous = false
  netsend

  puts '+ Turning off LEDs'
  $leds.each(&:off)
  puts '+ Clearing display'
  $display.clear!
  puts 'Done with cleanup, exiting'
  exit
end
Signal.trap('INT') { shutdown }
Signal.trap('TERM') { shutdown }

$dt_mode = Pin.new(pin: $config.pins.encoder.mode.dt)
$dt_a = Pin.new(pin: $config.pins.encoder.a.dt)
$dt_b = Pin.new(pin: $config.pins.encoder.b.dt)
$dt_c = Pin.new(pin: $config.pins.encoder.c.dt)

watch pin: $config.pins.encoder.mode.clk, trigger: :falling do
  if $dt_mode.read == 1
    # cw
    $mode_num += 1
    $mode_num = 0 if $mode_num >= $modes.length
    $logger.info "MODE UP: #{$mode_num} -- #{$modes[$mode_num].name}"
  else
    #ccw
    $mode_num -= 1
    $mode_num = ($modes.length - 1) if $mode_num < 0
    $logger.info "MODE DOWN: #{$mode_num} -- #{$modes[$mode_num].name}"
  end
  while read != 1
  end
  $mode = $modes[$mode_num]
  status(sta: AccessPoint.stations, new_mode: $mode)
end

def update
  return unless $continuous
  $current_p1 = $p1
  $current_p2 = $p2
  $current_p3 = $p3
end

watch pin: $config.pins.encoder.a.clk, trigger: :falling do
  if $dt_a.read == 1
    # cw
    $p1 += $increment
    $p1 = 255 if $p1 >= 255
    $logger.info "P1 UP: #{$p1}"
  else
    #ccw
    $p1 -= $increment
    $p1 = 0 if $p1 < 0
    $logger.info "P1 DOWN: #{$p1}"
  end
  while read != 1
  end
  update
  status(sta: AccessPoint.stations)
end


watch pin: $config.pins.encoder.b.clk, trigger: :falling do
  if $dt_b.read == 1
    # cw
    $p2 += $increment
    $p2 = 255 if $p2 >= 255
    $logger.info "P2 UP: #{$p2}"
  else
    #ccw
    $p2 -= $increment
    $p2 = 0 if $p2 < 0
    $logger.info "P2 DOWN: #{$p2}"
  end
  while read != 1
  end
  update
  status(sta: AccessPoint.stations)
end

watch pin: $config.pins.encoder.c.clk, trigger: :falling do
  if $dt_c.read == 1
    # cw
    $p3 += $increment
    $p3 = 255 if $p3 >= 255
    $logger.info "P3 UP: #{$p3}"
  else
    #ccw
    $p3 -= $increment
    $p3 = 0 if $p3 < 0
    $logger.info "P3 DOWN: #{$p3}"
  end
  while read != 1
  end
  update
  status(sta: AccessPoint.stations)
end

after pin: $config.pins.buttons.select, goes: :high, pull: :down do
  $logger.debug 'BUTTON: Select'
  $current_mode = $mode
  $current_mode_num = $mode_num
  $current_p1 = $p1
  $current_p2 = $p2
  $current_p3 = $p3
  status(sta: AccessPoint.stations)
end

after pin: $config.pins.buttons.send_now, goes: :high, pull: :down do
  $logger.debug 'BUTTON: Send Now'
  netsend if $continuous == false
end

after pin: $config.pins.buttons.all_off, goes: :high, pull: :down do
  $logger.debug 'BUTTON: All Off'
  $current_mode_num = 0 # TODO - Store all off somewhere in the config
  $current_mode = $modes[$current_mode_num]
  $current_p1 = 0
  $current_p2 = 0
  $current_p3 = 0
  $continuous = false
  netsend
  status(sta: AccessPoint.stations) # TODO - Why do I keep passing this?
end

after pin: $config.pins.buttons.continuous, goes: :high, pull: :down do
  $logger.debug 'BUTTON: Continuous'
  $continuous = true
  status(sta: AccessPoint.stations)
end

after pin: $config.pins.buttons.on_send, goes: :high, pull: :down do
  $logger.debug 'BUTTON: On Send'
  $continuous = false
  status(sta: AccessPoint.stations)
end

# Same as PiPiper.wait but we can do other things based on mode
loop do
  if $continuous
    $logger.debug 'Continuous Netsend'
    netsend
  end
  $logger.debug 'Sleep loop'
  sleep 1
end

