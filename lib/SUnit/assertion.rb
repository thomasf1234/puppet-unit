module SUnit
  class Assertion
    attr_reader :location, :expected, :actual

    def initialize(actual, expected)
      @actual = actual
      @expected = expected
      @location = caller_locations[0]
    end

    def true?
      @expected == @actual
    end
  end
end