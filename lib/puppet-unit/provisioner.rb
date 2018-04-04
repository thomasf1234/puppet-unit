require 'net/ssh'
require 'net/scp'
require 'json'

module PuppetUnit
  class Provisioner
    def initialize(host, identity_file="~/.ssh/deploy.id_rsa")
      @host = host
      @identity_file = identity_file
    end

    def init
      ssh do |session|
        puts "removing /etc/puppetlabs"
        session.exec!("sudo rm -rf /etc/puppetlabs")
        session.exec!("sudo mkdir -p /etc/puppetlabs && sudo chown deploy:deploy -R /etc/puppetlabs")
        session.exec!("mkdir -p /etc/puppetlabs/code/environments /etc/puppetlabs/code/modules")
        puts "uploading to /etc/puppetlabs/code/modules/#{cwd_name}"
        session.scp.upload!(".", "/etc/puppetlabs/code/modules/#{cwd_name}",  :recursive => true)

        module_dependencies.each do |module_dependency|
          puts "installing module dependency #{module_dependency}"
          session.exec!("puppet module install  --target-dir /etc/puppetlabs/code/modules #{module_dependency}")
        end
      end
    end

    def apply(setup_dir)
      ssh do |session|
        session.scp.upload!(setup_dir, "/etc/puppetlabs/code/environments/",  :recursive => true)
        session.exec!("mv /etc/puppetlabs/code/environments/setup /etc/puppetlabs/code/environments/test")
        session.exec!("sudo puppet apply --environment test --debug --modulepath /etc/puppetlabs/code/modules /etc/puppetlabs/code/environments/test")
      end
    end

    def assert(resources_manifest)
      ssh do |session|
        File.delete("tmp/lastrunreport.yaml") if File.directory?("tmp") & File.exist?("tmp/lastrunreport.yaml")
        Dir.mkdir("tmp") unless File.directory?("tmp")
        session.scp.upload!(resources_manifest, "/tmp")
        session.exec!("sudo rm -f /tmp/lastrunreport.yaml")
        session.exec!("sudo puppet apply --environment test --debug --noop --lastrunreport /tmp/lastrunreport.yaml --modulepath /etc/puppetlabs/code/modules /tmp/resources.pp")
        session.exec!("sudo chown deploy:deploy /tmp/lastrunreport.yaml")
        session.scp.download!("/tmp/lastrunreport.yaml", "tmp/")
      end
    end

    def facts
      ssh do |session|
        JSON.parse(session.exec!("puppet facts --basemodulepath /etc/puppetlabs/code/modules"))
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
          :keys => [ @identity_file ]
      }.merge(options)

      Net::SSH.start(@host, 'deploy', options) do |session|
        yield(session)
      end
    end
  end
end