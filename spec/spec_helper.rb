require 'bundler/setup'
require 'rails/all'
require 'salesforce_ar_sync'
require 'active_record'
require 'restforce'
require 'rspec'
require 'ammeter/init'
require 'vcr'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')
plugin_test_dir = File.dirname(__FILE__)

# Load sqlite3 mem database for testing
ActiveRecord::Base.configurations = YAML::load_file(File.join(plugin_test_dir, "db", "database.yml"))
ActiveRecord::Base.establish_connection((ENV["DB"] || "sqlite3mem").to_sym)
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, "db", "schema.rb"))

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
  #for each test that makes a request use a tape based on it's name
  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end
end

class Contact < ActiveRecord::Base
  salesforce_syncable sync_attributes:
                      {
                        FirstName: :first_name,
                        LastName: :last_name,
                        Phone: :phone_number,
                        Email: :email_address,
                        NumberOfPosts__c: :number_of_posts
                      },
                      readonly_fields: %i[NumberOfPosts__c]

  def phone_number=(new_phone_number)
    self.phone = new_phone_number
  end

  def email_address
    email
  end

  def email_address_changed?
    email_changed?
  end

  # Hack for Parsing into the proper Timezone
  def salesforce_updated_at=(updated_at)
    updated_at = Time.parse(updated_at) if updated_at.present? && updated_at.is_a?(String)
    write_attribute(:salesforce_updated_at, updated_at)
  end
end
