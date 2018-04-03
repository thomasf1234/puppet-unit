require "libvirt"

module PuppetUnit
  class LibvirtClient
    def initialize(params)
      @connect_uri = params["connect_uri"]
      @domain_name = params["domain"]
      @domain_network_name = params["network"]
      @domain_snapshot_name = params["snapshot"]
    end

    def domain_ip
      connect do |connection|
        network = connection.lookup_network_by_name(@domain_network_name)
        entry = network.dhcp_leases.detect {|entry| entry["hostname"] == @domain_name}

        if entry.nil?
          raise "no dhcp entry found for #{@domain_name}"
        else
          entry["ipaddr"]
        end
      end
    end

    def restore_snapshot
      connect do |connection|
        domain = connection.lookup_domain_by_name(@domain_name)
        snapshot = domain.lookup_snapshot_by_name(@domain_snapshot_name)
        domain.revert_to_snapshot(snapshot)
      end
    end

    private
    def connect
      connection = nil

      begin
        connection = ::Libvirt::open(@connect_uri)
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