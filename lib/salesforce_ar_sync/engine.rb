module SalesforceArSync
  class Engine < ::Rails::Engine
    initializer "salesforce_ar_sync.load_app_instance_data" do |app|
      SalesforceArSync.setup do |config|
        config.app_root = app.root

        #Load the configuration from the environment or a yaml file or disable it if no config present
        SalesforceArSync.config = Hash.new
        #load the config file if we have it
        config_path = "#{Rails.root}/config/salesforce_ar_sync.yml"
        if FileTest.exist?(config_path)
          config = YAML.load(ERB.new(File.read(config_path)).result)[Rails.env]
          SalesforceArSync.config["ORGANIZATION_ID"] = config['organization_id']
          SalesforceArSync.config["SYNC_ENABLED"] = config['sync_enabled']
          SalesforceArSync.config["IP_RANGES"] = config['ip_ranges'].split(',').map{ |ip| ip.strip }
          SalesforceArSync.config["NAMESPACE_PREFIX"] = config['namespace_prefix']
          SalesforceArSync.config['DELETION_MAP'] = config['deletion_map'].stringify_keys
        end

        #if we have ENV flags prefer them
        SalesforceArSync.config["ORGANIZATION_ID"] = ENV["SALESFORCE_AR_SYNC_ORGANIZATION_ID"] if ENV["SALESFORCE_AR_SYNC_ORGANIZATION_ID"]
        # env variables are usually strings so make sure, that SYNC_ENABLED is set to boolean ("false" is truthy)
        SalesforceArSync.config["SYNC_ENABLED"] = [true, "true"].include?(ENV["SALESFORCE_AR_SYNC_SYNC_ENABLED"]) if ENV.include? "SALESFORCE_AR_SYNC_SYNC_ENABLED"
        SalesforceArSync.config["IP_RANGES"] = ENV["SALESFORCE_AR_SYNC_IP_RANGES"].split(',').map{ |ip| ip.strip } if ENV["SALESFORCE_AR_SYNC_IP_RANGES"]
        SalesforceArSync.config["NAMESPACE_PREFIX"] = ENV["SALESFORCE_AR_NAMESPACE_PREFIX"] if ENV["SALESFORCE_AR_NAMESPACE_PREFIX"]
        SalesforceArSync.config['DELETION_MAP'] = ENV['DELETION_MAP'] if ENV['DELETION_MAP']

        #do we have valid config options now?
        if !SalesforceArSync.config["ORGANIZATION_ID"].present? || SalesforceArSync.config["ORGANIZATION_ID"].length != 18
          SalesforceArSync.config["SYNC_ENABLED"] = false
        end
      end
    end
  end
end
