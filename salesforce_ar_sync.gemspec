# -*- encoding: utf-8 -*-
require File.expand_path('../lib/salesforce_ar_sync/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Halliday", "Nick Neufeld", "Andrew Coates", "Devon Noonan", "Liam Nediger"]
  gem.email         = ["mhalliday@infotech.com", "nneufeld@infotech.com", "acoates@infotech.com", "dnoonan@infotech.com", "lnediger@infotech.com"]
  gem.description   = %q{ActiveRecord extension & rails engine for syncing data with Salesforce.com}
  gem.summary       = %q{ActiveRecord extension & rails engine for syncing data with Salesforce.com}
  gem.homepage      = "http://github.com/InfoTech/"

  gem.files         = Dir['README.md', 'LICENSE', 'lib/**/*', 'app/**/*', 'config/**/*']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "salesforce_ar_sync"
  gem.require_paths = ["lib"]
  gem.version       = SalesforceArSync::VERSION

  gem.add_dependency "rails", "~> 5.0"
  gem.add_dependency 'actionpack-xml_parser'

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "webmock"
  gem.add_development_dependency "vcr"
  gem.add_development_dependency "ammeter", '~> 1.1.2'
  gem.add_development_dependency "sqlite3"

  gem.add_runtime_dependency "databasedotcom"
end
