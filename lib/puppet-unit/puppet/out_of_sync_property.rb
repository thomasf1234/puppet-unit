module PuppetUnit
  module Puppet
    class OutOfSyncProperty
      attr_reader :name,
                  :actual_value,
                  :expected_value,
                  :message

      def initialize(property, previous_value, desired_value, message)
        @name = property
        @actual_value = previous_value
        @expected_value = desired_value
        @message = message
      end
    end
  end
end