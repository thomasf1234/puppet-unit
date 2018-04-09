require "puppet-unit/utils/unix_timestamp_utils"

module PuppetUnit
  class Lock
    include PuppetUnit::UnixTimestampUtils

    # ==== Description
    #
    # class constructor
    #
    # ==== Signature
    #
    # @author thomasf1234
    # @arg1   [String]    a uuid
    # @arg2   [Integer]   expiry time of the lock as a unix timestamp
    def initialize(lock_uuid, expires_at_unix_timestamp)
      @uuid = lock_uuid
      @expires_at_unix_timestamp = expires_at_unix_timestamp
    end

    # ==== Description
    #
    # the uuid assigned during initialization
    #
    # ==== Signature
    #
    # @author thomasf1234
    # @return [String]                    the uuid assigned
    # @see    PuppetUnit::Lock#initialize
    attr_reader :uuid

    # ==== Description
    #
    # the unix timestamp representing the lock expiry time, assigned during
    # initialization
    #
    # ==== Signature
    #
    # @author thomasf1234
    # @return [Integer]                   expiry time as unix timestamp
    # @see    PuppetUnit::Lock#initialize
    attr_reader :expires_at_unix_timestamp

    # ==== Description
    #
    # the time that the lock expires in 'Time' format
    #
    # ==== Signature
    #
    # @author thomasf1234
    # @return [Time]      the expiry time
    def expires_at
      Time.at(@expires_at_unix_timestamp)
    end

    # ==== Description
    #
    # if the lock is still active
    #
    # ==== Signature
    #
    # @author thomasf1234
    # @return [Boolean]   true if the lock has not yet expired, false otherwise
    def active?
      current_unix_timestamp < @expires_at_unix_timestamp
    end

    # ==== Description
    #
    # if the lock has expired
    #
    # ==== Signature
    #
    # @author thomasf1234
    # @return [Boolean]   true if the lock has expired, false otherwise
    def expired?
      !active?
    end

    def ==(other_lock)
      @uuid == other_lock.uuid && @expires_at_unix_timestamp == other_lock.expires_at_unix_timestamp
    end
  end
end