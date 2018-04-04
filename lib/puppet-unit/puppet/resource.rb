module PuppetUnit
  module Puppet
    class Resource
      attr_reader :resource,
                  :title,
                  :type,
                  :out_of_sync_properties

      def initialize(resource, title, type, containment_path, out_of_sync_properties)
        @resource = resource
        @title = title
        @type = type
        @containment_path = containment_path
        @out_of_sync_properties = out_of_sync_properties
      end

      def out_of_sync?
        @out_of_sync_properties.count > 0
      end

      def example?
        @containment_path.include?("Puppet_unit::Example")
      end
    end
  end
end
