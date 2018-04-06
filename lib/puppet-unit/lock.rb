require "puppet-unit/utils/unix_timestamp_utils"

module PuppetUnit
  class Lock
    include PuppetUnit::UnixTimestampUtils

    attr_reader :uuid, :expires_at_unix_timestamp

    def initialize(lock_uuid, expires_at_unix_timestamp)
      @uuid = lock_uuid
      @expires_at_unix_timestamp = expires_at_unix_timestamp
    end

    def expires_at
      Time.at(@expires_at_unix_timestamp)
    end

    def active?
      current_unix_timestamp < @expires_at_unix_timestamp
    end

    def expired?
      !active?
    end
  end
end