require 'ostruct'
require_relative 'config_reader'

class Configuration
  attr_reader :config
  def initialize(file)
    data = ConfigReader.load(file)
    raise "Config isn't a hash" unless data.is_a?(Hash)
    @config = DeepStruct.new(data['config'])
  end

  def method_missing(method, *args, &block)
    @config.send(method, *args)
  end
end
