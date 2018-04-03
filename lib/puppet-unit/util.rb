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
  end
end