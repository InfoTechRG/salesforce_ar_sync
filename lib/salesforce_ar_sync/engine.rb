module SalesforceArSync
  class Engine < ::Rails::Engine
    initializer "salesforce_ar_sync.load_app_instance_data" do |app|
      SalesforceArSync.setup do |config|
        config.app_root = app.root
        
        #Load the configuration from the environment or a yaml file or disable it if no config present
        SalesforceArSync.config = Hash.new

        #load the config file if we have it
        if FileTest.exist?("#{Rails.root}/config/salesforce_ar_sync.yml")
          config = YAML.load_file("#{Rails.root}/config/salesforce_ar_sync.yml")
          config = config[Rails.env]
          if config['organization_id'].present? && config['ip_ranges'].present? && config['sync_enabled'].present?
            SalesforceArSync.config["ORGANIZATION_ID"] = config['organization_id']
            SalesforceArSync.config["SYNC_ENABLED"] = config['sync_enabled']
            SalesforceArSync.config["IP_RANGES"] = config['ip_ranges'].split(',').map{ |ip| ip.strip }
          end
        end

        #if we have ENV flags prefer them
        SalesforceArSync.config["ORGANIZATION_ID"] = ENV["SALESFORCE_AR_SYNC_ORGANIZATION_ID"] if ENV["SALESFORCE_AR_SYNC_ORGANIZATION_ID"]
        SalesforceArSync.config["SYNC_ENABLED"] = ENV["SALESFORCE_AR_SYNC_SYNC_ENABLED"] if ENV.include? "SALESFORCE_AR_SYNC_SYNC_ENABLED"
        SalesforceArSync.config["IP_RANGES"] = ENV["SALESFORCE_AR_SYNC_IP_RANGES"].split(',').map{ |ip| ip.strip } if ENV["SALESFORCE_AR_SYNC_IP_RANGES"]

        #do we have valid config options now?
        if !SalesforceArSync.config["ORGANIZATION_ID"].present? || SalesforceArSync.config["ORGANIZATION_ID"].length != 18
          SalesforceArSync.config["SYNC_ENABLED"] = false
        end
      end
    end
  end
end