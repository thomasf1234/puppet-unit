module PuppetUnit
  module Exceptions
    class LockfileExists < RuntimeError
      attr_reader :lockfile_path

      def initialize(lockfile_path)
        @lockfile_path = lockfile_path
      end
    end
  end
end