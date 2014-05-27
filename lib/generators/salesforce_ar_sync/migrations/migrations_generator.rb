require 'rails/generators/active_record'

module SalesforceArSync
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      desc "Generates migrations to add required columns for Salesforce sync on specified models."

      #The migrate option is used to specify whether to run the migrations in the end or not
      class_option :migrate, :type => :string, :banner => "[yes|no]", :lazy_default => "yes"
      #The list of models to create migrations for
      argument :models, :type => :array, :banner => "model1 model2 model3...", :required => true


      def create_migrations
        models.each do |model|
          create_ar_sync_migration(model)
        end

        if options[:migrate] == "yes" 
          say "Performing Migrations"
          run_migrations
        end
      end

      protected

      def run_migrations
        rake("db:migrate")
      end

      def self.next_migration_number(path)
        unless @prev_migration_nr
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        else
          @prev_migration_nr += 1
        end
        @prev_migration_nr.to_s
      end

      def create_ar_sync_migration(model_name)
        #we can't load all the models in so let's assume it follows the standard nameing convention
        @table_name = model_name.tableize
        @model_name = model_name

        migration_template "migration.rb", "db/migrate/add_salesforce_fields_to_#{@table_name}.rb"
      end 
    end
  end
end