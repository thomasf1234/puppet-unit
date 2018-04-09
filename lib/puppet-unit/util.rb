module PuppetUnit
  class Util
    def self.flat_hash(input, base = nil, all = {})
      if input.is_a?(Array)
        input = input.each_with_index.to_a.each(&:reverse!)
      end

      if input.is_a?(Hash) || input.is_a?(Array)
        input.each do |k, v|
          flat_hash(v, base ? "#{base}::#{k}" : k, all)
        end
      else
        all[base] = input
      end

      all
    end

    def self.refresh_tmp
      tmp_dir = "tmp"

      if File.directory?(tmp_dir)
        FileUtils.remove_dir(tmp_dir)
      end
      Dir.mkdir(tmp_dir)
    end

    def self.minutes_and_seconds(time)
      seconds = time.to_i
      "#{seconds / 60}m #{seconds % 60}s"
    end

    def self.seconds(time)
      "%0.1f" % time
    end
  end
end