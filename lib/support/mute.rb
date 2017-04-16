class Mute
  def self.method_missing(name, *args, &block)
    Mute
  end

  def self.to_s
    ''
  end
end