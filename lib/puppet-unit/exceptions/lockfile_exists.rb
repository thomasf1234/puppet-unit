module PuppetUnit
  module Exceptions
    class LockfileExists < RuntimeError
      def initialize(lockfile_path)
        @lockfile_path = lockfile_path
      end
    end
  end
end