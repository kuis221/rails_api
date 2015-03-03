# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'legacy/version'

Gem::Specification.new do |gem|
  gem.name          = "legacy"
  gem.version       = Legacy::VERSION
  gem.authors       = ["Guillermo Vargas"]
  gem.email         = ["guilleva@gmail.com"]
  gem.description   = %q{Adds access to old Legacy application data}
  gem.summary       = %q{It takes the company_id from the current logged in user and assigns it to the models}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.require_paths = ["lib"]

  gem.add_dependency 'activerecord', '~> 4'
  gem.add_dependency 'railties', '~> 4'
  gem.add_dependency 'paperclip', '~> 4.1'
  gem.add_development_dependency "rspec", "~>2.0"
end
