# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zero_authorization/version'

Gem::Specification.new do |spec|
  spec.name          = "zero_authorization"
  spec.version       = ZeroAuthorization::VERSION
  spec.authors       = ["Rajeev Kannav Sharma", "Praveen Kumar Sinha"]
  spec.email         = ["rajeevsharma86@gmail.com", "praveen.kumar.sinha@gmail.com"]
  spec.description   = "Functionality to add authorization on Rails model's write operations plus any other set of defined methods."
  spec.summary       = "How to setup: Specify what any specific role of current root entity(logged_user) can do/can't do in roles_n_privileges.yml and (re-)boot application."
  spec.homepage      = "https://github.com/rajeevkannav/zero_authorization"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', "~> 1.3"
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'activesupport', '~> 0'
end
