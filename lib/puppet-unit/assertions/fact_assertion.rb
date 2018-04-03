module PuppetUnit
  class FactAssertion < PuppetUnit::Assertion
    attr_reader :expected_fact, :actual_facts

    def initialize(expected_fact, actual_facts)
      super()
      @expected_fact = expected_fact
      @actual_facts = actual_facts
    end

    def description
      "Asserting that #{@expected_fact.key} is #{@expected_fact.value}"
    end

    def failed_message_lines
      actual_fact = @actual_facts.detect {|fact| fact.key == @expected_fact.key}

      if actual_fact.nil?
        ["Fact '#{@expected_fact.key}' not found"]
      else
        ["Expected '#{@expected_fact.value}', got '#{actual_fact.value}'"]
      end
    end

    def true?
      @actual_facts.include?(@expected_fact)
    end
  end
end