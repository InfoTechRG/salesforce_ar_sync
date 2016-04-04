module SalesforceArSync
  module SoapHandler
    class Delete < SalesforceArSync::SoapHandler::Base
      def process_notifications(priority = 90)
        batch_process do |sobject|
          SalesforceArSync::SoapHandler::Delete.delay(priority: priority, run_at: 5.seconds.from_now).delete_object(sobject)
        end
      end

      def self.delete_object(hash = {})
        raise ArgumentError, 'Object_Id__c parameter required' if hash[namespaced(:Object_Id__c)].blank?
        raise ArgumentError, 'Object_Type__c parameter required' if hash[namespaced(:Object_Type__c)].blank?
        raise Exception, "Deletion failed: No class found for #{hash[namespaced(:Object_Type__c)]}" unless deletion_map(hash[namespaced(:Object_Type__c)]).safe_constantize

        object = deletion_map(hash[namespaced(:Object_Type__c)]).safe_constantize.try(:find_by_salesforce_id, hash[namespaced(:Object_Id__c)])

        object.destroy if object && object.ar_sync_inbound_delete?
      end
    end
  end
end
