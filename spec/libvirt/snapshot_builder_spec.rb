RSpec.describe PuppetUnit::Libvirt::SnapshotBuilder do
  let(:domain) { double(Libvirt::Domain, active?: active, xml_desc: domain_xml_desc.strip) }
  let(:domain_xml_desc) do
    <<EOF
<domain type='kvm' id='5'>
  <name>tst-ub14</name>
  <uuid>dc886941-ee01-4f01-a30a-8351904d648f</uuid>
  <memory unit='KiB'>2000896</memory>
  <currentMemory unit='KiB'>2000000</currentMemory>
  <vcpu placement='static'>2</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-xenial'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/kvm-spice</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/tst-ub14.qcow2'/>
      <backingStore/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/tst-ub14-1.qcow2'/>
      <backingStore/>
      <target dev='vdb' bus='virtio'/>
      <alias name='virtio-disk1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </disk>
    <controller type='usb' index='0'>
      <alias name='usb'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <interface type='network'>
      <mac address='52:54:00:93:bf:3d'/>
      <source network='default' bridge='virbr0'/>
      <target dev='vnet0'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/6'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/6'>
      <source path='/dev/pts/6'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='5900' autoport='yes' listen='0.0.0.0'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
    <video>
      <model type='cirrus' vram='16384' heads='1'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <stats period='5'/>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='apparmor' relabel='yes'>
    <label>libvirt-dc886941-ee01-4f01-a30a-8351904d648f</label>
    <imagelabel>libvirt-dc886941-ee01-4f01-a30a-8351904d648f</imagelabel>
  </seclabel>
</domain>
EOF
  end

  context "inactive domain" do
    let(:active) { false }
    let(:overrides) do
      {
          "name" => "test-snapshot",
          "description" => "This is a test snapshot"
      }
    end

    let(:expected_xml) do
      <<EOF
<domainsnapshot>
  <name>test-snapshot</name>
  <description>This is a test snapshot</description>
  <state>shutoff</state>
  <memory snapshot='no'/>
  <disks>
    <disk name='vda' snapshot='internal'/>
    <disk name='vdb' snapshot='internal'/>
  </disks>
  #{domain_xml_desc}
</domainsnapshot>
EOF
    end

    it "yields the expected xml" do
      actual = PuppetUnit::Libvirt::SnapshotBuilder.new(domain, overrides).build.to_s
      expected = REXML::Document.new(expected_xml).to_s
      expect_xml_eql?(actual, expected)
    end
  end

  context "active domain" do
    let(:active) { true }
    let(:overrides) do
      {
          "name" => "test-snapshot",
          "description" => "This is a test snapshot"
      }
    end

    let(:expected_xml) do
      <<EOF
<domainsnapshot>
  <name>test-snapshot</name>
  <description>This is a test snapshot</description>
  <state>running</state>
  <memory snapshot='internal'/>
  <disks>
    <disk name='vda' snapshot='internal'/>
    <disk name='vdb' snapshot='internal'/>
  </disks>
  #{domain_xml_desc}
</domainsnapshot>
EOF
    end

    it "yields the expected xml" do
      actual = PuppetUnit::Libvirt::SnapshotBuilder.new(domain, overrides).build.to_s
      expected = REXML::Document.new(expected_xml).to_s
      expect_xml_eql?(actual, expected)
    end
  end
end


