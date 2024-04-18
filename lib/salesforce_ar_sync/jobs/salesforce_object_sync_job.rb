# frozen_string_literal: true

module SalesforceArSync
  # simple object to be serialized when asynchronously sending data to Salesforce
  class SalesforceObjectSyncJob < BaseJob
    def perform(web_object_name, salesforce_id, attributes)
      web_object = web_object_name.to_s.constantize.find_by_salesforce_id salesforce_id
      # object exists in salesforce if we call its system_mod_stamp
      if web_object&.system_mod_stamp&.present?
        web_object.salesforce_update_object(JSON.parse(attributes))
        web_object.update_attribute(:salesforce_updated_at, web_object.system_mod_stamp)
      end
    end
  end
end
