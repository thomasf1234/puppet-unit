require "rexml/document"
require "rexml/element"

module PuppetUnit
  module Libvirt
    class SnapshotBuilder
      attr_reader :overrides

      # overrides = {
      #     "name" => "mysnapshot",
      #     "desc" => "mysnapshot description"
      # }
      def initialize(domain, overrides={})
        @overrides = overrides
        @domain = domain

        #default overrides
        @overrides["name"] ||= "snapshot"
        @overrides["desc"] ||= "a snapshot of vm disk images"
      end

      def build
        doc = REXML::Document.new
        doc.add_element(root_element)
        doc
      end

      private

      def root_element
        state = @domain.active? ? "running" : "shutoff"
        memory_snapshot = @domain.active? ? "internal" : "no"
        domain_doc = REXML::Document.new(@domain.xml_desc)

        _domainsnapshot_element = element("domainsnapshot")
        _domainsnapshot_element.add_element(element("name", {}, @overrides["name"]))
        _domainsnapshot_element.add_element(element("description", {}, @overrides["description"]))
        _domainsnapshot_element.add_element(element("state", {}, state))
        _domainsnapshot_element.add_element(element("memory", {"snapshot" => memory_snapshot}))
        _domainsnapshot_element.add_element(disks_element(domain_doc))
        _domainsnapshot_element.add_element(domain_doc)
        _domainsnapshot_element
      end

      def disks_element(domain_doc)
        disks = REXML::XPath.match(domain_doc, "/domain/devices/disk/target/@dev").map(&:value)
        _disks_element = REXML::Element.new("disks")

        disks.each do |disk|
          disk_element = REXML::Element.new("disk")
          disk_element.add_attributes({"name" => disk, "snapshot" => "internal"})
          _disks_element.add_element(disk_element)
        end
        _disks_element
      end

      def element(name, attributes={}, text=nil)
        _element = REXML::Element.new(name)
        _element.add_attributes(attributes)
        _element.text = text
        _element
      end
    end
  end
end
