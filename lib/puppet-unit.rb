require "puppet-unit/version"
require "puppet-unit/util"

require "puppet-unit/services/log_service"
require "puppet-unit/services/config_service"
require "puppet-unit/services/resource_service"
require "puppet-unit/services/lockfile_service"
require "puppet-unit/services/libvirt_service"

require "puppet-unit/provisioner"
require "puppet-unit/result"
require "puppet-unit/assertion"
require "puppet-unit/test"
require "puppet-unit/test_runner"
require "puppet-unit/puppet/out_of_sync_property"
require "puppet-unit/puppet/resource"
require "puppet-unit/puppet/fact"
require "puppet-unit/assertions/fact_assertion"
require "puppet-unit/assertions/resource_assertion"
require "puppet-unit/tests/module_test"

module PuppetUnit
  # Your code goes here...
  def self.root
    File.dirname(__dir__)
  end
end
