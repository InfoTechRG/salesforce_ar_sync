module SalesforceArSync
  class Engine < ::Rails::Engine
    initializer "salesforce_ar_sync.load_app_instance_data" do |app|
      SalesforceArSync.setup do |config|
        config.app_root = app.root
      end
    end
  end
end