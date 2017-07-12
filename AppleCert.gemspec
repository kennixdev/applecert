# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'AppleCert/version'

Gem::Specification.new do |spec|
  spec.name          = "applecert"
  spec.version       = AppleCert::VERSION
  spec.authors       = ["Kennix"]
  spec.email         = ["kennixdev@gmail.com"]

  spec.summary       = %q{for manage apple cert and provisioing}
  spec.description   = %q{mac tools for manage apple cert and provisioing}
  spec.homepage      = "https://github.com/kennixdev/applecert"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

#  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files         = Dir['lib/*'] + Dir['exe/*'] + Dir['lib/**/*']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency "thor", "~> 0.19.4"
  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "nokogiri", "~> 1.7"
  spec.add_dependency "plist", "~> 3.1"
  spec.add_dependency "openssl", "~> 2.0"
end
