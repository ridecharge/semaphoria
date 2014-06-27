# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'semaphoria/version'

Gem::Specification.new do |spec|
  spec.name          = "semaphoria"
  spec.version       = Semaphoria::VERSION
  spec.authors       = ["Jonathan Calvert"]
  spec.email         = ["jcalvert@taximagic.com"]
  spec.summary       = %q{Simple client gem for interacting with Semaphoria}
  spec.description   = %q{Very basic gem wrapper to lock calls}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_dependency('httparty')
  spec.add_dependency('addressable')
  spec.add_development_dependency('minitest')
  spec.add_development_dependency('webmock')
  spec.add_development_dependency('vcr')
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
