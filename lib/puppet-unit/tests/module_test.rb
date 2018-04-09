require 'yaml'
require 'json'
require "puppet-unit/util"

module PuppetUnit
  class ModuleTest < PuppetUnit::Test
    def initialize(test_dir, domain_name)
      super()
      @test_dir = test_dir
      @domain_name = domain_name

      raise "#{@test_dir} not a directory" unless File.directory?(@test_dir)

      @setup_dir = File.join(@test_dir, "setup")
      raise "#{@setup_dir} not a directory" unless File.directory?(@setup_dir)

      @assertions_dir = File.join(@test_dir, "assertions")
      raise "#{@assertions_dir} not a directory" unless File.directory?(@assertions_dir)

      @conf_file = File.join(@test_dir, "config.yaml")
      raise "#{@conf_file} not a file" unless File.file?(@conf_file)
      @config = YAML.load_file(@conf_file)

      @provisioner = PuppetUnit::Provisioner.new(domain_name)
    end


    def setup
      PuppetUnit::Services::LogService.instance.debug("Refreshing tmp directory")
      PuppetUnit::Util.refresh_tmp

      @provisioner.lock
      @provisioner.prepare
      @provisioner.apply(@setup_dir)
      @provisioner.assert(File.join(@assertions_dir, "resources.pp"))
      @facts = to_facts(PuppetUnit::Util.flat_hash(@provisioner.facts["values"]))
      @provisioner.clear_lock
    end

    def set_assertions
      set_resource_assertions
      set_fact_assertions
    end

    #@Override
    def description
      "#{@domain_name} - #{@config["description"]}"
    end

    private
    def set_resource_assertions
      lastrunresources.each do |resource|
        assertion = PuppetUnit::ResourceAssertion.new(resource)
        @assertions << assertion
      end
    end

    def set_fact_assertions
      expected_facts_path = File.join(@assertions_dir, "facts.yaml")
      if File.exist?(expected_facts_path)
        expected_facts = to_facts(YAML.load_file(expected_facts_path))
        expected_facts.each do |expected_fact|
          @assertions << PuppetUnit::FactAssertion.new(expected_fact, @facts)
        end
      end
    end

    def to_facts(raw_facts)
      raw_facts.map do |key, value|
        PuppetUnit::Puppet::Fact.new(key, value)
      end
    end

    def lastrunresources(lastrunreport_path="tmp/lastrunreport.yaml")
      if File.exist?(lastrunreport_path)
        yamltext = File.read(lastrunreport_path)
        yamltext.sub!(/^--- \!.*$/,'---')
        lastrunreport = YAML.load(yamltext)

        resources = []
        lastrunreport["resource_statuses"].each do |resource_key, status|
          out_of_sync_properties = status["events"].map do |event|
            PuppetUnit::Puppet::OutOfSyncProperty.new(event["property"],
                                                 event["previous_value"],
                                                 event["desired_value"],
                                                 event["message"])
          end

          resource = PuppetUnit::Puppet::Resource.new(resource_key,
                                                 status["title"],
                                                 status["resource_type"],
                                                 status["containment_path"],
                                                 out_of_sync_properties)

          resources << resource
        end

        resources.select(&:example?)
      else
        raise "#{lastrunreport_path} not found"
      end
    end
  end
end
