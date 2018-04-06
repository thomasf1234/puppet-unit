require "singleton"
require "libvirt"
require "puppet-unit/services/config_service"
require "puppet-unit/libvirt/snapshot_builder"

module PuppetUnit
  module Services
    class LibvirtService
      include Singleton

      def domain_ip(domain_name, network_name="default")
        connect do |connection|
          network = connection.lookup_network_by_name(network_name)
          entry = network.dhcp_leases.detect {|entry| entry["hostname"] == domain_name}

          if entry.nil?
            raise "no dhcp entry found for #{domain_name}"
          else
            entry["ipaddr"]
          end
        end
      end

      def restore_snapshot(domain_name, snapshot_name)
        connect do |connection|
          domain = connection.lookup_domain_by_name(domain_name)
          snapshot = domain.lookup_snapshot_by_name(snapshot_name)
          domain.revert_to_snapshot(snapshot)
        end
      end

      def connect_uri
        PuppetUnit::Services::ConfigService.instance.get("libvirt")["connect_uri"]
      end

      private
      def connect
        connection = nil

        begin
          connection = ::Libvirt::open(connect_uri)
          yield(connection)
        ensure
          if !connection.nil?
            if !connection.closed? || connection.alive?
              connection.close
            end
          end
        end
      end
    end
  end
end