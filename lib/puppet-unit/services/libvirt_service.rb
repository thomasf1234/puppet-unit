require "singleton"
require "libvirt"
require 'rexml/document'
require "puppet-unit/services/config_service"
require "puppet-unit/libvirt/snapshot_builder"

module PuppetUnit
  module Services
    class LibvirtService
      DOMAIN_STATE = {
          0 => "nostate",
          1 => "running",
          2 => "blocked",
          3 => "paused",
          4 => "shutdown",
          5 => "shutoff",
          6 => "crashed",
          7 => "pmsuspended",
          8 => "last",
      }

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
          #get mac_addr of first domain network interface card assigned to network_name
          domain = connection.lookup_domain_by_name(domain_name)
          domain_doc = REXML::Document.new(domain.xml_desc)
          domain_mac_addr = REXML::XPath.first(domain_doc, "string(/domain/devices/interface/source[@network='#{network_name}']/ancestor::interface/mac/@address)")

          #use domain mac_addr to query dhcp entries of network
          network = connection.lookup_network_by_name(network_name)
          network_doc = REXML::Document.new(network.xml_desc)
          _domain_ip = REXML::XPath.first(network_doc, "string(/network/ip/dhcp/host[@mac='#{domain_mac_addr}']/@ip)")

          if _domain_ip.empty?
            raise("no dhcp entry found for #{domain_name}")
          else
            _domain_ip
          end
        end
      end

      def domain_state(domain_name)
        connect do |connection|
          domain = connection.lookup_domain_by_name(domain_name)
          DOMAIN_STATE[domain.state[0]]
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

      def delete_snapshots_later_than(domain_name, snapshot_name)
        connect do |connection|
          domain = connection.lookup_domain_by_name(domain_name)

          delete_later_than_snapshot = domain.lookup_snapshot_by_name(snapshot_name)
          delete_later_than_timestamp = snapshot_creation_time(delete_later_than_snapshot)

          snapshots = domain.list_all_snapshots.reject do |snapshot|
            snapshot.name == snapshot_name
          end

          snapshots.each do |snapshot|
            if snapshot_creation_time(snapshot) > delete_later_than_timestamp
              PuppetUnit::Services::LogService.instance.debug("Deleting snapshot #{snapshot.name}")
              snapshot.delete
            end
          end
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

      def snapshot_creation_time(snapshot)
        snapshot_doc = REXML::Document.new(snapshot.xml_desc)
        creation_time_unix_timestamp = REXML::XPath.first(snapshot_doc, "string(/domainsnapshot/creationTime)").to_i
        creation_time_unix_timestamp
      end
    end
  end
end