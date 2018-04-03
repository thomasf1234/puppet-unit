module PuppetUnit
  class ResourceAssertion < PuppetUnit::Assertion
    attr_reader :resource

    def initialize(resource)
      super()
      @resource = resource
    end

    def description
      "Asserting that #{resource.resource} is in the expected state"
    end

    def failed_message_lines
      message_array = ["#{resource.resource} out of sync:"]
      resource.out_of_sync_properties.each do |property|
        message_array << "property '#{property.name}' :: #{property.message.strip}"
      end
      message_array
    end

    def true?
      !@resource.out_of_sync?
    end
  end
end