require "singleton"

module PuppetUnit
  module Singletons
    class Resource
      include Singleton

      #returns File
      def get(resource_filename)
        resource_filepath = File.join(PuppetUnit.root, "resources", resource_filename)

        if File.exist?(resource_filepath) && File.file?(resource_filepath)
          File.new(resource_filepath, "r")
        else
          raise("resource not found at #{resource_filepath}")
        end
      end
    end
  end
end