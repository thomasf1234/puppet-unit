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

        threads = []

        tests.group_by(&:domain_name).each do |domain_name, module_tests|
          thread = Thread.new do
            module_tests.each_with_index do |test, index|
              test_number = index + 1
              test.log.append(format("#{test_number}) #{test.class.name}", :bold))
              test.log.append(format("   Description: #{test.description}", :bold))

              if test.skip?
                test.skip
                test.log.append(format("   Result: Test skipped *", :yellow))
              else
                begin
                  test.start

                  begin
                    test.setup
                    test.set_assertions

                    test.assertions.each do |assertion|
                      begin
                        test.log.append(format("   Assertion: #{assertion.description}", :light_blue))

                        if assertion.true?
                          assertion.result.pass
                          test.log.append(format("   Result: Assertion passed ✔", :green))
                        else
                          assertion.result.fail
                          test.log.append(format("   Result: Assertion failed ✘", :red))
                          assertion.failed_message_lines.each do |line|
                            test.log.append(format("   ==> #{line}", :red))
                          end
                        end
                      rescue => assertion_ex
                        assertion.result.fail
                        log_error(test, assertion_ex)
                      end
                    end
                  rescue => test_ex
                    #reach here if exception raised during setup
                    test.error
                    log_error(test, test_ex)
                  end
                ensure
                  test.teardown
                  test.finish
                  test.log.append(format("   Duration: #{PuppetUnit::Util.seconds(test.duration)}s", :light_blue))
                end
              end
            end
          end

          threads << thread
        end

        threads.each(&:join)
        finish

        print_result(tests)
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
      if finished?
        @finished_at - @started_at
      elsif started?
        Time.now - @started_at
      end
    end

    def order(tests)
      case PuppetUnit::Services::ConfigService.instance.get("order")
        when "rand"
          tests.shuffle
        else
          tests
      end
    end

    def log_error(test, exception)
      test.log.append(format("   #{exception.class.name} :: #{exception.message}", :red))
      exception.backtrace.each do |line|
        test.log.append(format("   #{line}", :red))
      end
    end

    def format(string, colour)
      colour.nil? ? string : "\e[#{STRING_FORMAT_CODES[colour]}m#{string}\e[0m"
    end

    def print_result(tests)
      tests.each do |test|
        test.log.print
        puts("")
      end
      
      puts(format("Finished in #{PuppetUnit::Util.minutes_and_seconds(duration)}", :light_blue))
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
