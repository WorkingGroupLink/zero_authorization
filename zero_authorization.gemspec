# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = "zero_authorization"
  spec.version       = "2.0.2"
  spec.authors       = ["Michal Kracik", "Mike Bijon", "Rajeev Kannav Sharma", "Praveen Kumar Sinha"]
  spec.email         = ["rajeevsharma86@gmail.com", "praveen.kumar.sinha@gmail.com"]
  spec.description   = "Functionality to add authorization on Rails model write operations plus any other set of defined methods."
  spec.summary       = "How to setup: Specify what any specific role of current root entity(logged_user) can do/can't do in roles_n_privileges.yml and (re-)boot application."
  spec.homepage      = "https://github.com/WorkingGroupLink/zero_authorization"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', "~> 1.3"
  spec.add_development_dependency 'activesupport', '~> 5'
end
