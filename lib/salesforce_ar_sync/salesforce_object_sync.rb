module SalesforceArSync
  # simple object to be serialized when asynchronously sending data to Salesforce
  class SalesforceObjectSync < ActiveJob::Base
    def perform(web_object_name, salesforce_id, attributes)
      web_object = "#{web_object_name}".constantize.find_by_salesforce_id salesforce_id
      # object exists in salesforce if we call its system_mod_stamp
      if (system_mod_stamp = web_object.system_mod_stamp)
        web_object.salesforce_update_object(JSON.parse(attributes))
        web_object.update_attribute(:salesforce_updated_at, system_mod_stamp)
      end
    end
  end
end
