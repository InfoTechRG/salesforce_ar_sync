module SalesforceArSync
  # simple object to be serialized when asynchronously sending data to Salesforce
  class SalesforceObjectSync < Struct.new(:web_object_name, :salesforce_id, :attributes)
    def perform
      web_object = "#{web_object_name}".constantize.find_by_salesforce_id salesforce_id

      # object exists in salesforce if we call its system_mod_stamp
      return if system_mod_stamp == web_object.system_mod_stamp

      web_object.salesforce_update_object(web_object.salesforce_attributes_to_update(true))
      web_object.update_attribute(:salesforce_updated_at, system_mod_stamp)
    end
  end
end
