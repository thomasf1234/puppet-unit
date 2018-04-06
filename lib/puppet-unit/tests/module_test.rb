require 'yaml'
require 'json'

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
    end


    def setup
      PuppetUnit::Services::LogService.instance.debug("Refreshing tmp directory")
      refresh_tmp



      PuppetUnit::Services::LogService.instance.debug("Restoring domain snapshot #{@domain_name}")
      PuppetUnit::Services::LibvirtService.instance.restore_snapshot(@domain_name)

      PuppetUnit::Services::LogService.instance.debug("Looking up domain ip address")
      domain_ip = PuppetUnit::Services::LibvirtService.instance.domain_ip(@domain_name)

      identify_file = PuppetUnit::Services::ConfigService.get("libvirt")["identity_file"]
      provisioner = PuppetUnit::Provisioner.new(domain_ip, identify_file)


      provisioner.init
      provisioner.apply(@setup_dir)
      provisioner.assert(File.join(@assertions_dir, "resources.pp"))
      @facts = to_facts(PuppetUnit::Util.flat_hash(provisioner.facts["values"]))
    end

    def set_assertions
      set_resource_assertions
      set_fact_assertions
    end

    private
    def refresh_tmp
      if File.directory?("tmp")
        FileUtils.remove_dir("tmp")
      end
      Dir.mkdir("tmp")
    end

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
