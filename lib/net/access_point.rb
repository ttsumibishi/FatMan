class AccessPoint
  def self.pid
    return `pidof hostapd`
  end

  def self.stations
    list = `iw dev wlan0 station dump | grep ^Station | wc -l`
    list.chomp!
    return list
  end

  def self.enabled?
    return self.pid.length > 0
  end
end