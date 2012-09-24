module SalesforceArSync
  module Extenders
    module SalesforceSyncable      
      def salesforce_syncable(options = {})
        require 'salesforce_ar_sync/salesforce_sync'
        include SalesforceArSync::SalesforceSync

        self.salesforce_sync_enabled = options.has_key?(:salesforce_sync_enabled) ? options[:salesforce_sync_enabled] : true
        self.salesforce_sync_attribute_mapping = options.has_key?(:sync_attributes) ? options[:sync_attributes].stringify_keys : {}
        self.salesforce_async_attributes = options.has_key?(:async_attributes) ? options[:async_attributes] : {}
        self.salesforce_default_attributes_for_create = options.has_key?(:default_attributes_for_create) ? options[:default_attributes_for_create] : {}
        self.salesforce_id_attribute_name = options.has_key?(:salesforce_id_attribute_name) ? options[:salesforce_id_attribute_name] : :Id
        self.salesforce_web_id_attribute_name = options.has_key?(:web_id_attribute_name) ? options[:web_id_attribute_name] : :WebId__c
        self.salesforce_sync_web_id = options.has_key?(:salesforce_sync_web_id) ? options[:salesforce_sync_web_id] : false
        self.salesforce_web_class_name = options.has_key?(:web_class_name) ? options[:web_class_name] : self.name
        
        self.salesforce_object_name_method = options.has_key?(:salesforce_object_name) ? options[:salesforce_object_name] : nil
        self.salesforce_object_method = options.has_key?(:salesforce_object) ? options[:salesforce_object] : nil
        self.salesforce_skip_sync_method = options.has_key?(:except) ? options[:except] : nil
        
        instance_eval do
          before_save :salesforce_sync
          after_create :sync_web_id     
          
          def salesforce_sync_web_id?
            self.salesforce_sync_web_id
          end
        end
        
        class_eval do
          # Calls a method if provided to return the name of the Salesforce object the model is syncing to.
          # If no method is provided, defaults to the class name
          def salesforce_object_name
            return send(self.class.salesforce_object_name_method) if self.class.salesforce_object_name_method.present?
            return self.class.name
          end
          
          # Calls a method, if provided, to retrieve an object from Salesforce. Calls the default implementation if
          # no custom method is specified
          def salesforce_object
            return send(self.class.salesforce_object_method) if self.class.salesforce_object_method.present?
            return send(:salesforce_object_default)
          end
          
          # Calls a method, if provided, to determine if a record should be synced to Salesforce. 
          # The salesforce_skip_sync instance variable is also used.
          # The SALESFORCE_AR_SYNC_ENABLED flag overrides all the others if set to false
          def salesforce_skip_sync?
            return true if SalesforceArSync.config["SYNC_ENABLED"] == false
            return (salesforce_skip_sync || !self.class.salesforce_sync_enabled || send(self.class.salesforce_skip_sync_method)) if self.class.salesforce_skip_sync_method.present?
            return (salesforce_skip_sync || !self.class.salesforce_sync_enabled)
          end
        end
      end
    end
  end
end