module PuppetUnit
  class TestLog
    def initialize
      @lines = []
    end

    def append(content, log_level="raw")
      @lines << {"content" => content, "log_level" => log_level}
    end

    def print
      @lines.each do |line|
        PuppetUnit::Services::LogService.instance.send(line["log_level"], line["content"])
      end
    end
  end
end