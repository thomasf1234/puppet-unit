module PuppetUnit
  module UnixTimestampUtils
    ONE_HOUR_UNIX_TIMESTAMP = 60*60
    # @param [Integer] the number of hours
    # @return [Integer] the unix timestamp representing the current time at number_of_hours from now
    def future_unix_timestamp(number_of_hours)
      current_unix_timestamp + (ONE_HOUR_UNIX_TIMESTAMP * number_of_hours)
    end

    # @param [Integer] the current unix time
    def current_unix_timestamp
      Time.now.to_i
    end
  end
end