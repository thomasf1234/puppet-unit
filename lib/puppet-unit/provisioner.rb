require 'net/ssh'
require 'net/scp'
require 'json'
require 'fileutils'
require "puppet-unit/services/log_service"
require "puppet-unit/services/lockfile_service"
require "puppet-unit/services/libvirt_service"
require "puppet-unit/services/resource_service"
require "puppet-unit/exceptions/host_locked"

module PuppetUnit
  class Provisioner
    def initialize(domain_name)
      @domain_name = domain_name
      @domain_ip = PuppetUnit::Services::LibvirtService.instance.domain_ip(domain_name, domain_config["network"])
      @remote_environment_dir = "/etc/puppetlabs/code/environments/test"
      @remote_modules_dir = "/etc/puppetlabs/code/modules/"
      @remote_data_dir = "/etc/puppetlabs/puppet/data/environments/test/"
    end

    def lock
      PuppetUnit::Services::LogService.instance.debug("Checking domain state")
      domain_state = PuppetUnit::Services::LibvirtService.instance.domain_state(@domain_name)

      if domain_state == "shutoff"
        PuppetUnit::Services::LogService.instance.debug("Domain shutdown")
      elsif domain_state == "running"
        PuppetUnit::Services::LogService.instance.debug("Domain running")
        ssh do |session|
          PuppetUnit::Services::LogService.instance.debug("Checking for existing lock")
          if session.exec!("test -f /tmp/module_test.marshal && printf true") == "true"
            PuppetUnit::Services::LogService.instance.debug("Existing lock found, downloading")
            session.scp.download!("/tmp/module_test.marshal", "/tmp/existing_module_test.marshal")
            existing_remote_lock = PuppetUnit::Services::LockfileService.instance.read("/tmp/existing_module_test.marshal")

            if existing_remote_lock.expired?
              PuppetUnit::Services::LogService.instance.debug("Existing lock has expired, continuing")
            else
              raise(PuppetUnit::Exceptions::HostLocked.new(@domain_ip))
            end
          end
        end
      else
        raise("Domain in unexpected state #{domain_state}")
      end

      PuppetUnit::Services::LogService.instance.debug("Restoring domain snapshot #{@domain_name}")
      PuppetUnit::Services::LibvirtService.instance.restore_snapshot(@domain_name, domain_config["snapshot"])

      PuppetUnit::Services::LogService.instance.debug("Deleting newer snapshots of #{domain_config["snapshot"]}")
      PuppetUnit::Services::LibvirtService.instance.delete_snapshots_later_than(@domain_name, domain_config["snapshot"])

      PuppetUnit::Services::LogService.instance.debug("Creating lock")
      lock = PuppetUnit::Services::LockfileService.instance.get
      PuppetUnit::Services::LockfileService.instance.write(lock, "tmp/module_test.marshal")

      ssh do |session|
        PuppetUnit::Services::LogService.instance.debug("Uploading our lock")
        session.scp.upload!("tmp/module_test.marshal", "/tmp/module_test.marshal")
        PuppetUnit::Services::LogService.instance.debug("Verifying our remote lock")
        session.scp.download!("/tmp/module_test.marshal", "tmp/remote_module_test.marshal")
        remote_lock = PuppetUnit::Services::LockfileService.instance.read("tmp/remote_module_test.marshal")

        if remote_lock == lock
          PuppetUnit::Services::LogService.instance.debug("Remote lock verified - successfully locked host")
          true
        else
          raise(PuppetUnit::Exceptions::HostLocked.new(@domain_ip))
        end
      end
    end

    def prepare
      ssh do |session|
        PuppetUnit::Services::LogService.instance.debug("Clearing /etc/puppetlabs")
        session.exec!("sudo rm -rf /etc/puppetlabs")
        puppetlabs_dirtree_tgz_filename = "puppetlabs-dirtree.tar.gz"
        puppetlabs_dirtree_tgz = PuppetUnit::Services::ResourceService.instance.get("puppetlabs-dirtree.tar.gz")

        PuppetUnit::Services::LogService.instance.debug("Uploading #{puppetlabs_dirtree_tgz.path} to /tmp/#{puppetlabs_dirtree_tgz_filename}")
        session.scp.upload!(puppetlabs_dirtree_tgz.path, "/tmp/#{puppetlabs_dirtree_tgz_filename}")
        PuppetUnit::Services::LogService.instance.debug("Extracting /tmp/#{puppetlabs_dirtree_tgz_filename} to /etc/puppetlabs")
        session.exec!("sudo mkdir -p /etc/puppetlabs && sudo tar -mxz -f /tmp/#{puppetlabs_dirtree_tgz_filename} -C /etc/puppetlabs")
        PuppetUnit::Services::LogService.instance.debug("Setting permissions under /etc/puppetlabs")
        session.exec!("sudo chown deploy:deploy -R /etc/puppetlabs")

        if system("tar -zc -f tmp/#{cwd_name}.tgz --exclude tmp .")
          PuppetUnit::Services::LogService.instance.debug("uploading tmp/#{cwd_name}.tgz to /tmp/#{cwd_name}.tgz")
          session.scp.upload!("tmp/#{cwd_name}.tgz", "/tmp/#{cwd_name}.tgz")
          PuppetUnit::Services::LogService.instance.debug("Extracting /tmp/#{cwd_name}.tgz to /etc/puppetlabs/code/modules/#{module_name}")
          session.exec!("mkdir -p /etc/puppetlabs/code/modules/#{module_name} && tar -mxz -f /tmp/#{cwd_name}.tgz -C /etc/puppetlabs/code/modules/#{module_name}")

          module_dependencies.each do |module_dependency|
            PuppetUnit::Services::LogService.instance.debug("Installing module dependency #{module_dependency}")
            session.exec!("puppet module install --target-dir /etc/puppetlabs/code/vendor #{module_dependency}")
          end

          PuppetUnit::Services::LogService.instance.debug("Creating snapshot 'test_prepared'")
          PuppetUnit::Services::LibvirtService.instance.create_snapshot(@domain_name, "test_prepared", "domain has had #{cwd_name} installed with module dependencies")
        else
          raise("Failed to create tar of module")
        end
      end
    end

    # TODO CLEAR LOCK IN TEARDOWN!!!!
    def apply(setup_dir)
      ssh do |session|
        manifests_dir = File.join(setup_dir, "manifests")
        data_file = File.join(setup_dir, "data", "base.yaml")
        module_dir = File.join(setup_dir, "modules", "helper")
        
        PuppetUnit::Services::LogService.instance.debug("Uploading #{manifests_dir} to #{@remote_environment_dir}")
        session.scp.upload!(manifests_dir, @remote_environment_dir, :recursive => true)
        PuppetUnit::Services::LogService.instance.debug("Uploading #{data_file} to #{@remote_data_dir}")
        session.scp.upload!(data_file, @remote_data_dir)

        if File.exist?(module_dir)
          PuppetUnit::Services::LogService.instance.debug("Uploading #{module_dir} to #{@remote_modules_dir}")
          session.scp.upload!(module_dir, @remote_modules_dir, :recursive => true)
        end
        puppet_log = session.exec!("sudo -i puppet apply --debug --environment test #{@remote_environment_dir}")
        File.open("tmp/lastrunapply.log", "w") { |file| file.write(puppet_log) }
      end
    end

    def assert(resources_manifest)
      ssh do |session|
        File.delete("tmp/lastrunreport.yaml") if File.directory?("tmp") & File.exist?("tmp/lastrunreport.yaml")
        session.scp.upload!(resources_manifest, "/tmp")
        session.exec!("sudo rm -f /tmp/lastrunreport.yaml")
        noop_log = session.exec!("sudo puppet apply --environment test --debug --noop --lastrunreport /tmp/lastrunreport.yaml --modulepath #{@remote_modules_dir} /tmp/resources.pp")
        File.open("tmp/lastrunnoop.log", "w") { |file| file.write(noop_log) }
        session.exec!("sudo chown deploy:deploy /tmp/lastrunreport.yaml")
        session.scp.download!("/tmp/lastrunreport.yaml", "tmp/")
      end
    end

    def facts
      ssh do |session|
        facts_json = session.exec!("puppet facts --basemodulepath #{@remote_modules_dir}")
        File.open("tmp/actual_facts.json", "w") { |file| file.write(facts_json) }
        JSON.parse(facts_json)
      end
    end

    def clear_lock
      ssh do |session|
        if session.exec!("test -f /tmp/module_test.marshal && printf true") == "true"
          PuppetUnit::Services::LogService.instance.debug("Removing our lock")
          session.exec!("rm -f /tmp/module_test.marshal")

          if session.exec!("test -f /tmp/module_test.marshal && printf true") == "true"
            raise("Failed to remove lock")
          end
        else
          PuppetUnit::Services::LogService.instance.debug("Lockfile not found")
        end
      end
    end

    private
    def module_dependencies
      if File.exist?("metadata.json")
        metadata_json = JSON.parse(File.read("metadata.json"))
        metadata_json["dependencies"].map do |dependency|
          dependency["name"]
        end
      else
        []
      end
    end

    def cwd_name
      File.basename(Dir.getwd)
    end

    def ssh(options={})
      options = {
          :host_key => "ssh-rsa",
          :keys => [ domain_config["ssh_identity_file"] ],
          :verify_host_key => Net::SSH::Verifiers::Never.new
      }.merge(options)

      Net::SSH.start(@domain_ip, domain_config["ssh_user"], options) do |session|
        yield(session)
      end
    end

    def module_name
      PuppetUnit::Services::ConfigService.instance.get("module_name") || cwd_name
    end

    def domain_config
      PuppetUnit::Services::ConfigService.instance.get("libvirt")["domains"][@domain_name]
    end
  end
end
