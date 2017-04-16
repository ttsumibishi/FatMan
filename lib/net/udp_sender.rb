require 'socket'

class UdpSender
  def initialize(params)
    @broadcast = params[:broadcast]
    @activity = params[:activity_led]
    @socket = UDPSocket.new
    @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
  end

  def send(payload)
    puts payload
    require 'pp'
    pp payload
    chars = payload.split
    #chars[0] = chars[0].unpack('H*')[0]
    #chars[1] = chars[1].to_i.to_s(16)
    #chars[2] = chars[2].to_i.to_s(16).rjust(2, '0')
    #chars[3] = chars[3].to_i.to_s(16).rjust(2, '0')
    chars[1] = chars[1].to_i.chr
    chars[2] = chars[2].to_i.chr
    chars[3] = chars[3].to_i.chr
    #pp chars
    @socket.send(chars.join, Socket::SO_BROADCAST, @broadcast, 2390)
    #@socket.send(bytes, Socket::SO_BROADCAST, @broadcast, 2390)
    @activity.on
    sleep 0.05
    @activity.off
  end
end