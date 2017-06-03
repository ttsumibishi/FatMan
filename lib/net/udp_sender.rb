require 'socket'

class UdpSender
  def initialize(params)
    @broadcast = params[:broadcast]
    @activity = params[:activity_led]
    @socket = UDPSocket.new
    @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
  end

  def send(payload)
    chars = payload.split
    chars[1] = chars[1].to_i.chr
    chars[2] = chars[2].to_i.chr
    chars[3] = chars[3].to_i.chr
    @socket.send(chars.join, Socket::SO_BROADCAST, @broadcast, 2390)
    @activity.on
    sleep 0.05
    @activity.off
  end
end