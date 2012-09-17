require 'bundler/setup'
require 'rails/all'
require 'salesforce_ar_sync'
require 'supermodel'
require 'databasedotcom'
require 'rspec'
require 'ammeter/init'
require 'vcr'

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

VCR.configure do |c|
  c.cassette_library_dir =  "vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.allow_http_connections_when_no_cassette = true
  c.default_cassette_options = {
      :match_requests_on => [:method,
        VCR.request_matchers.uri_without_param(:client_id, :client_secret, :username, :password)]
    }
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true

  #for each test that makes a request use a tape based on it's name
  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end
end
