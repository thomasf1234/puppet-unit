require "puppet-unit/test_log"

module PuppetUnit
  class Test
    module States
      NOT_STARTED = "NOT_STARTED"
      STARTED = "STARTED"
      FINISHED = "FINISHED"
      SKIPPED = "SKIPPED"
    end

    attr_reader :state, :assertions, :log

    def initialize
      @state = States::NOT_STARTED
      @assertions = []
      @has_error = false
      @log = PuppetUnit::TestLog.new
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

    def has_error?
      @has_error
    end

    def passed?
      !has_error? && assertions.all?(&:passed?)
    end

    def failed?
      !passed?
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

    def error
      @has_error = true
    end

    def duration
      _duration = if finished?
                    @finished_at - @started_at
                  elsif started?
                    Time.now - @started_at
                  end

      "%0.1f" % _duration
    end

    def skip?
      @config["skip"] ||= false
    end

    def title
      self.class.name
    end

    def description
      @config["description"]
    end

    def setup

    end

    #array of PuppetUnit::Assertion
    def set_assertions
      raise NotImplementedError.new("Subclasses must implement #{__method__}")
    end

    def teardown

    end
  end
end