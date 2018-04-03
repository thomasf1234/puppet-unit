
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "puppet-unit/version"

Gem::Specification.new do |spec|
  spec.name          = "puppet-unit"
  spec.version       = PuppetUnit::VERSION
  spec.authors       = ["abstractx1"]

  spec.summary       = %q{Simple puppet unit testing gem.}
  spec.description   = %q{Simple puppet unit testing gem.}
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = "puppet-unit"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"

  spec.add_runtime_dependency "ruby-libvirt"
end
