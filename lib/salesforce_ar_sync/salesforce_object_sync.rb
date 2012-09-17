module SalesforceArSync
  # simple object to be serialized when asynchronously sending data to Salesforce
  class SalesforceObjectSync < Struct.new(:web_object_name, :salesforce_object_name, :salesforce_id, :attributes)
    def perform        
      sf_object = "Databasedotcom::#{salesforce_object_name}".constantize.find_by_Id salesforce_id
    
      if sf_object
        sf_object.update_attributes(attributes)
        sf_object.reload
    
        web_object = "#{web_object_name}".constantize.find_by_salesforce_id salesforce_id
        web_object.update_attribute(:salesforce_updated_at, sf_object.SystemModstamp) unless web_object.nil?
      end
    end
  end
end