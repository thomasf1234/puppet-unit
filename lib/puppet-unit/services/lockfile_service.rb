require "singleton"
require "securerandom"
require "puppet-unit/lock"
require "puppet-unit/exceptions/lockfile_exists"
require "puppet-unit/utils/unix_timestamp_utils"

module PuppetUnit
  module Services
    class LockfileService
      ONE_HOUR_UNIX_TIMESTAMP = 60*60

      include Singleton
      include PuppetUnit::UnixTimestampUtils

      # ==== Description
      #
      # Calling the method to acquire a new lock with a random uuid that will has an
      # expiration date of 5 hours
      #
      # ==== Signature
      #
      # @author thomasf1234
      # @return [PuppetUnit::Lock] a new lock object that expires in 5 hours
      def get
        PuppetUnit::Lock.new(SecureRandom.uuid, future_unix_timestamp(5))
      end


      # ==== Description
      #
      # Serializes and writes a Lock instance to a file in marshal format.
      #
      # ==== Signature
      #
      # @author thomasf1234
      # @arg1   [PuppetUnit::Lock]  lock instance to serialize to file
      # @arg2   [String]            file path to write lockfile
      # @return [Integer]           number of bytes written to lockfile_path
      # @see    LockfileService#get
      def write(lock, lockfile_path)
        if File.exist?(lockfile_path)
          raise(PuppetUnit::Exception::LockfileExists.new(lockfile_path))
        else
          serialized_lock = Marshal.dump(lock)

          File.open(lockfile_path, "wb") do |file|
            file.write(serialized_lock)
          end
        end
      end

      # ==== Description
      #
      # Call to read a lockfile created using LockfileService#write
      #
      # ==== Signature
      #
      # @author thomasf1234
      # @arg1   [String]              file path to the lockfile
      # @return [PuppetUnit::Lock]    the lock object that was serialized at lockfile_path
      # @see    LockfileService#write
      def read(lockfile_path)
        Marshal.load(File.binread(lockfile_path))
      end
    end
  end
end


