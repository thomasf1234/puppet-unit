module PuppetUnit
  class Assertion
    attr_reader :result

    def initialize
      @result = PuppetUnit::Result.new
    end

    def description
      raise NotImplementedError.new("Subclasses must implement #{__method__}")
    end

    def failed_message_lines
      raise NotImplementedError.new("Subclasses must implement #{__method__}")
    end

    def true?
      raise NotImplementedError.new("Subclasses must implement #{__method__}")
    end

    def passed?
      @result.pass?
    end

    def failed?
      !passed?
    end
  end
end