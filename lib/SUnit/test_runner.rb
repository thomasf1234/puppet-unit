module SUnit
  class TestRunner
    STRING_FORMAT_CODES = {
        bold: 1,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        light_blue: 36
    }

    module States
      PENDING = "PENDING"
      STARTED = "STARTED"
      FINISHED = "FINISHED"
    end

    attr_reader :state

    def initialize(tests)
      @state = States::PENDING
      @tests = tests
    end

    def run
      if pending?
        start
        tests = order(@tests)
        tests.each_with_index do |test, index|
          test_number = index + 1
          puts format("#{test_number}) #{test.class.name}", :bold)
          puts format("   Description: #{test.description}", :light_blue)

          if test.skip?
            skip(test)
          else
            begin
              test.start
              test.setup

              #test.assertion must return an assertion instance
              test_assertion = test.assertion
              # raise "test assertion must return SUnit::Assertion instance" if !test_assertion.kind_of?(SUnit::Assertion)

              if test_assertion.true?
                pass(test)
              else
                fail(test)
              end
            rescue => e
              error(test, e)
            ensure
              test.teardown
              test.finish
              puts(format("   Duration: #{test.duration}s", :light_blue))
              puts("")
            end
          end
        end

        finish

        puts("")
        puts(format("Finished in #{duration} seconds", :light_blue))
        puts(format("#{tests.reject(&:skip?).count} ran, #{tests.select(&:passed?).count} passed, #{tests.select(&:failed?).count} failed", :light_blue))
      else
        raise "run called when not in PENDING state."
      end
    end

    def pending?
      @state == States::PENDING
    end

    def started?
      @state == States::STARTED
    end

    def finished?
      @state == States::FINISHED
    end

    def start
      @state = States::STARTED
      @started_at = Time.now
    end

    def finish
      @state = States::FINISHED
      @finished_at = Time.now
    end

    def duration
      _duration = if finished?
                    @finished_at - @started_at
                  elsif started?
                    Time.now - @started_at
                  end

      "%0.1f" % _duration
    end

    def order(tests)
      case SUnit::Config.instance.get("order")
        when "rand"
          tests.shuffle
        else
          tests
      end
    end

    def format(string, colour)
      colour.nil? ? string : "\e[#{STRING_FORMAT_CODES[colour]}m#{string}\e[0m"
    end

    def skip(test)
      test.skip
      puts(format("   Result: Test skipped *", :yellow))
    end

    def pass(test)
      test.result.pass
      puts(format("   Result: Test passed ✔", :green))
    end

    def fail(test)
      test.result.fail
      puts(format("   Result: Test failed ✘", :red))
      code_snippet = File.readlines(test.assertion.location.path)[test.assertion.location.lineno-1]
      puts(format("   ==> #{code_snippet.strip} : expected #{test.assertion.expected} but got #{test.assertion.actual}", :red))
      puts(format("   ==> #{test.assertion.location.path}", :red))
    end

    def error(test, exception)
      fail(test)
      puts(format("  #{exception.class.name} :: #{exception.message}", :red))
      exception.backtrace.each do |line|
        puts(format("  #{line}", :red))
      end
    end
  end
end