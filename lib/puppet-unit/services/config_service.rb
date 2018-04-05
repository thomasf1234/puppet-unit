require 'singleton'
require 'yaml'

module PuppetUnit
  module Services
    class ConfigService
      include Singleton

      DEFAULT_CONFIG = {
          "order" => "rand",
          "libvirt" => {
              "connect_uri" => "qemu:///system",
          }
      }

      def get(key)
        @config[key.to_s]
      end

      private
      def initialize
        @config = load_yaml("puppet-unit/config.yaml", DEFAULT_CONFIG)
      end

      def load_yaml(file_path, defaults)
        File.exist?(file_path) ? YAML.load_file(file_path) : defaults
      end
    end
  end
end