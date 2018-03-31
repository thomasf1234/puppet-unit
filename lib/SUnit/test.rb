module SUnit
  class Test
    module States
      NOT_STARTED = "NOT_STARTED"
      STARTED = "STARTED"
      FINISHED = "FINISHED"
      SKIPPED = "SKIPPED"
    end

    attr_reader :state, :result

    def initialize
      @state = States::NOT_STARTED
      @result = Result.new
    end

    def started?
      @state == States::STARTED
    end

    def finished?
      @state == States::FINISHED
    end

    def skipped?
      @state == States::SKIPPED
    end

    def passed?
      @result.pass?
    end

    def failed?
      @result.fail?
    end

    def start
      @state = States::STARTED
      @started_at = Time.now
    end

    def finish
      @state = States::FINISHED
      @finished_at = Time.now
    end

    def skip
      @state = States::SKIPPED
    end

    def duration
      _duration = if finished?
                    @finished_at - @started_at
                  elsif started?
                    Time.now - @started_at
                  end

      "%0.1f" % _duration
    end

    #Override
    def skip?
      false
    end

    def title
      self.class.name
    end

    def description
      raise NotImplementedError.new("Subclasses must implement #{__method__}")
    end

    def setup

    end

    def test
      raise NotImplementedError.new("Subclasses must implement #{__method__}")
    end

    def teardown

    end
  end
end