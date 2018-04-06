require "singleton"
require "securerandom"
require "puppet-unit/exceptions/lockfile_exists"
require "puppet-unit/utils/unix_timestamp_utils"

module PuppetUnit
  module Services
    class LockfileService
      ONE_HOUR_UNIX_TIMESTAMP = 60*60

      include Singleton
      include PuppetUnit::UnixTimestampUtils

      # @return [PuppetUnit::Lock] a new lock object that expires in 5 hours
      def get
        PuppetUnit::Lock.new(SecureRandom.uuid, future_unix_timestamp(5))
      end


      #returns number of bytes written
      # @param [PuppetUnit::Lock]  lock to serialize to file
      # @param [String]            file path to write lockfile
      # @return [Integer] the number of bytes written to file
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

      # @param [String] file path to lockfile
      # @return [PuppetUnit::Lock] the lock object that was serialized at lockfile_path
      def read(lockfile_path)
        Marshal.load(File.binread(lockfile_path))
      end
    end
  end
end


