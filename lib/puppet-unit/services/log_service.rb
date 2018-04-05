require "singleton"
require "logger"

module PuppetUnit
  module Services
    class LogService
      include Singleton

      def fatal(message)
        @logger.fatal(message)
      end

      def error(message)
        @logger.error(message)
      end

      def warn(message)
        @logger.warn(message)
      end

      def info(message)
        @logger.info(message)
      end

      def debug(message)
        @logger.debug(message)
      end

      private
      def initialize
        @logging_level = ENV.has_key?("LOG_LEVEL") ? ENV["LOG_LEVEL"].to_i : 1
        @logger = Logger.new(STDOUT)
        @logger.level = @logging_level
      end
    end
  end
end