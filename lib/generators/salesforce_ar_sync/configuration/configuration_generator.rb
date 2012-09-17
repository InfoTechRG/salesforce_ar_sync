module SalesforceArSync
  module Generators
    class ConfigurationGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      desc "Generates migrations to add required columns for Salesforce sync on specified models."

      argument :organization_id, :type => :string, :banner => "organization_id", :default => "#18 character organization_id"

      def create_yaml
        template "salesforce_ar_sync.yml", "config/salesforce_ar_sync.yml"
      end
    end
  end
end