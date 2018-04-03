module PuppetUnit
  module Puppet
    class Fact
      attr_reader :key, :value
      
      def initialize(key, value)
        @key = key
        @value = value
      end

      def ==(fact)
        @key == fact.key && @value == fact.value
      end

      def inspect
        "{#{@key} => #{@value}}"
      end
    end
  end
end