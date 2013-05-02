# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'company_scoped/version'

Gem::Specification.new do |gem|
  gem.name          = "company_scoped"
  gem.version       = CompanyScoped::VERSION
  gem.authors       = ["Guillermo Vargas"]
  gem.email         = ["guilleva@gmail.com"]
  gem.description   = %q{TODO: Makes a model scoped to a company}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activerecord', '~> 3'
  gem.add_dependency 'sentient_user', '~> 0.3.2'
  gem.add_dependency 'railties', '~> 3'
end
