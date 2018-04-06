module PuppetUnit
  class TestRunner
    STRING_FORMAT_CODES = {
        bold: 1,
        red: 31,
        green: 32,
        yellow: 33,
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
          PuppetUnit::Services::LogService.instance.raw(format("#{test_number}) #{test.class.name}", :bold))
          PuppetUnit::Services::LogService.instance.raw(format("   Description: #{test.description}", :bold))

          if test.skip?
            skip(test)
          else
            begin
              test.start

              begin
                test.setup
                test.set_assertions

                test.assertions.each do |assertion|
                  begin
                    puts(format("   Assertion: #{assertion.description}", :light_blue))

                    if assertion.true?
                      pass(assertion)
                    else
                      fail(assertion)
                    end
                  rescue => assertion_ex
                    assertion.result.fail
                    print_error(assertion_ex)
                  end
                end
              rescue => test_ex
                #reach here if exception raised during setup
                test.error
                print_error(test_ex)
              end
            ensure
              test.teardown
              test.finish
              puts(format("   Duration: #{test.duration}s", :light_blue))
            end
          end

          puts("")
        end

        finish
        print_result
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
      case PuppetUnit::Services::ConfigService.instance.get("order")
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

    def pass(assertion)
      assertion.result.pass
      puts(format("   Result: Assertion passed ✔", :green))
    end

    def fail(assertion)
      assertion.result.fail
      puts(format("   Result: Assertion failed ✘", :red))
      assertion.failed_message_lines.each do |line|
        puts(format("   ==> #{line}", :red))
      end
    end

    def print_error(exception)
      puts(format("   #{exception.class.name} :: #{exception.message}", :red))
      exception.backtrace.each do |line|
        puts(format("   #{line}", :red))
      end
    end

    def print_result
      puts("")
      puts(format("Finished in #{duration} seconds", :light_blue))
      ran_tests = @tests.reject(&:skip?)
      ran_count = ran_tests.count
      passed_count = ran_tests.reject(&:has_error?).select(&:passed?).count
      failed_count = ran_tests.reject(&:has_error?).select(&:failed?).count
      errored_count = ran_tests.select(&:has_error?).count
      colour = passed_count == ran_count ? :green : :red

      puts(format("#{ran_count} ran, #{passed_count} passed, #{failed_count} failed, #{errored_count} errored", colour))
    end
  end
end