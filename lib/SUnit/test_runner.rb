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
      RUNNING = "RUNNING"
      FINISHED = "FINISHED"
    end

    attr_reader :state

    def initialize(tests)
      @state = States::PENDING
      @tests = tests
    end

    def run
      if pending?
        @state = States::RUNNING
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
              if test.test
                pass(test)
              else
                fail(test)
              end
            rescue => e
              error(test, e)
            ensure
              test.teardown
              finish(test)
            end
          end
        end

        @state = States::FINISHED
      else
        raise "run called when not in PENDING state."
      end
    end

    def pending?
      @state == States::PENDING
    end

    def running?
      @state == States::RUNNING
    end

    def finished?
      @state == States::FINISHED
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
    end

    def error(test, exception)
      fail(test)
      puts(format("  #{exception.class.name} :: #{exception.message}", :red))
      exception.backtrace.each do |line|
        puts(format("  #{line}", :red))
      end
    end

    def finish(test)
      test.finish
      puts(format("   Duration: #{test.duration}s", :light_blue))
    end
  end
end