module PuppetUnit
  module Exceptions
    class HostLocked < RuntimeError
      attr_reader :host

      def initialize(host)
        super("Host #{host} has already been locked")
        @host = host
      end
    end
  end
end