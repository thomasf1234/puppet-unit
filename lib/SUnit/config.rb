require 'yaml'
require 'singleton'

module SUnit
  class Config
    include Singleton

    DEFAULT_CONFIG = {
        "order" => "rand"
    }

    def get(key)
      @config[key.to_s]
    end

    private
    def initialize
      super
      @config = load_yaml('sunit/config.yaml', DEFAULT_CONFIG)
    end

    def load_yaml(file_path, defaults)
      File.exist?(file_path) ? YAML.load_file(file_path) : defaults
    end
  end
end