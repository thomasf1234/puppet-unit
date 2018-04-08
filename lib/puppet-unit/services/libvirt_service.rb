require "singleton"
require "libvirt"
require "puppet-unit/services/config_service"
require "puppet-unit/libvirt/snapshot_builder"

module PuppetUnit
  module Services
    class LibvirtService
      include Singleton

      # ==== Description
      #
      # Returns the current IP address assigned to the provided domain name in the
      # provided network
      #
      # ==== Signature
      #
      # @author    thomasf1234
      # @arg1      [String]       the domain to query
      # @arg2      [String]       the network to query
      # @return    [String]       the IP address
      # @exception [RuntimeError] could not find an IP address
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

      def create_snapshot(domain_name, snapshot_name, snapshot_desc)
        overrides = {
            "name" => snapshot_name,
            "description" => snapshot_desc
        }

        connect do |connection|
          domain = connection.lookup_domain_by_name(domain_name)
          create_snapshot_xml = Libvirt::SnapshotBuilder.new(domain, overrides).build.to_s
          domain.snapshot_create_xml(create_snapshot_xml)
        end
      end


      # ==== Description
      #
      # Restores the provided domain to the provided snapshot.
      #
      # ==== Signature
      #
      # @author    thomasf1234
      # @arg1      [String]         the name of the domain to restore
      # @arg2      [String]         the snapshot to restore
      # @return    [TrueClass]      true
      # @exception [Libvirt::Error] error occurred restoring snapshot
      def restore_snapshot(domain_name, snapshot_name)
        connect do |connection|
          domain = connection.lookup_domain_by_name(domain_name)
          snapshot = domain.lookup_snapshot_by_name(snapshot_name)
          domain.revert_to_snapshot(snapshot)
          true
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