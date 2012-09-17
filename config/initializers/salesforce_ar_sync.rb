#Load the configuration from the environment or a yaml file or disable it if no config present
SALESFORCE_AR_SYNC_CONFIG = Hash.new

#load the config file if we have it
if FileTest.exist?("#{Rails.root}/config/salesforce_ar_sync.yml")
  config = YAML.load_file("#{Rails.root}/config/salesforce_ar_sync.yml")
  config = config[Rails.env]
  if config['organization_id'].present? && config['ip_ranges'].present? && config['sync_enabled'].present?
    SALESFORCE_AR_SYNC_CONFIG["ORGANIZATION_ID"] = config['organization_id']
    SALESFORCE_AR_SYNC_CONFIG["SYNC_ENABLED"] = config['sync_enabled']
    SALESFORCE_AR_SYNC_CONFIG["IP_RANGES"] = config['ip_ranges'].split(',').map{ |ip| ip.strip }
  end
end

#if we have ENV flags prefer them
SALESFORCE_AR_SYNC_CONFIG["ORGANIZATION_ID"] = ENV["SALESFORCE_AR_SYNC_ORGANIZATION_ID"] if ENV["SALESFORCE_AR_SYNC_ORGANIZATION_ID"]
SALESFORCE_AR_SYNC_CONFIG["SYNC_ENABLED"] = ENV["SALESFORCE_AR_SYNC_SYNC_ENABLED"] if ENV.include? "SALESFORCE_AR_SYNC_SYNC_ENABLED"
SALESFORCE_AR_SYNC_CONFIG["IP_RANGES"] = ENV["SALESFORCE_AR_SYNC_IP_RANGES"].split(',').map{ |ip| ip.strip } if ENV["SALESFORCE_AR_SYNC_IP_RANGES"]

#do we have valid config options now?
if !SALESFORCE_AR_SYNC_CONFIG["ORGANIZATION_ID"].present? || SALESFORCE_AR_SYNC_CONFIG["ORGANIZATION_ID"].length != 18
  SALESFORCE_AR_SYNC_CONFIG["SYNC_ENABLED"] = false
end