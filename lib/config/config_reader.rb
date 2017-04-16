require 'yaml'

class ConfigReader
  def self.load(file)
    return YAML.load(File.read(file))
  end
end

