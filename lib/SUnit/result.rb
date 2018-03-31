module SUnit
  class Result
    module States
      PENDING = "PENDING"
      PASS = "PASS"
      FAIL = "FAIL"
    end

    attr_reader :state, :result

    def initialize
      @state = States::PENDING
    end

    def pending?
      @state == States::PENDING
    end

    def pass?
      @state == States::PASS
    end

    def fail?
      @state == States::FAIL
    end

    def pass
      @state = States::PASS
    end

    def fail
      @state = States::FAIL
    end
  end
end