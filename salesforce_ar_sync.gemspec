require File.expand_path('lib/salesforce_ar_sync/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Michael Halliday', 'Nick Neufeld', 'Andrew Coates', 'Devon Noonan', 'Liam Nediger']
  gem.email         = ['mhalliday@infotech.com', 'nneufeld@infotech.com', 'acoates@infotech.com', 'dnoonan@infotech.com', 'lnediger@infotech.com']
  gem.description   = 'ActiveRecord extension & rails engine for syncing data with Salesforce.com'
  gem.summary       = 'ActiveRecord extension & rails engine for syncing data with Salesforce.com'
  gem.homepage      = 'http://github.com/InfoTech/'

  gem.files         = Dir['README.md', 'LICENSE', 'lib/**/*', 'app/**/*', 'config/**/*']
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.name          = 'salesforce_ar_sync'
  gem.require_paths = ['lib']
  gem.version       = SalesforceArSync::VERSION

  gem.add_dependency 'actionpack-xml_parser'
  gem.add_dependency 'rails', '>= 5'
  gem.add_dependency 'restforce', '~> 5.0.5'
  gem.add_dependency 'rexml', '~> 3.2'
end
