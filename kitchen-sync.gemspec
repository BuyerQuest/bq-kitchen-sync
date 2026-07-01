# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen-sync/version'

Gem::Specification.new do |spec|
  spec.name          = 'bq-kitchen-sync'
  spec.version       = KitchenSync::VERSION
  spec.authors       = ['Andrew Bobulsky', 'Noah Kantrowitz']
  spec.email         = ['devops@buyerquest.com']
  spec.description   = %q{Improved file transfers for for test-kitchen}
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/BuyerQuest/kitchen-sync'
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files`.split($/).grep(%r{\A(?:lib/|CHANGELOG\.md|Gemfile|LICENSE|README\.md|Rakefile|kitchen-sync\.gemspec)})
  spec.executables   = []
  spec.test_files    = []
  spec.require_paths = ['lib']

  spec.add_dependency 'benchmark'
  spec.add_dependency 'net-sftp', '>= 4.0.0'
  spec.add_dependency 'net-ssh', '>= 7.0', '< 8.0'
  spec.add_dependency 'test-kitchen', '~> 4.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'kitchen-ec2', '~> 3.22'
  spec.add_development_dependency 'kitchen-cinc', '~> 1.1'
  spec.add_development_dependency 'kitchen-inspec'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
end
