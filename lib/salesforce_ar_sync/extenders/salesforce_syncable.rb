module SalesforceArSync
  module Extenders
    module SalesforceSyncable
      def salesforce_syncable(options = {})
        require 'salesforce_ar_sync/salesforce_sync'
        include SalesforceArSync::SalesforceSync

        self.salesforce_sync_enabled = options.fetch(:salesforce_sync_enabled, true)
        self.salesforce_sync_attribute_mapping = options.key?(:sync_attributes) ? options[:sync_attributes].stringify_keys : {}
        self.salesforce_async_attributes = options.fetch(:async_attributes, {})
        self.salesforce_default_attributes_for_create = options.fetch(:default_attributes_for_create, {})
        self.salesforce_id_attribute_name = options.fetch(:salesforce_id_attribute_name, :Id)
        self.salesforce_web_id_attribute_name = options.fetch(:web_id_attribute_name, :WebId__c)
        self.activerecord_web_id_attribute_name = options.fetch(:activerecord_web_id_attribute_name, :id)
        self.salesforce_sync_web_id = options.fetch(:salesforce_sync_web_id, false)
        self.salesforce_web_class_name = options.fetch(:web_class_name, name)

        self.sync_inbound_delete = options.fetch(:sync_inbound_delete, true)
        self.sync_outbound_delete = options.fetch(:sync_outbound_delete, false)
        self.unscoped_updates = options.fetch(:unscoped_updates, false)

        self.salesforce_object_name_method = options.fetch(:salesforce_object_name, nil)
        self.salesforce_skip_sync_method = options.fetch(:except, nil)

        instance_eval do
          before_save :salesforce_sync
          after_create :sync_web_id
          after_commit :salesforce_delete_object, on: :destroy

          def salesforce_sync_web_id?
            salesforce_sync_web_id
          end
        end

        class_eval do
          # Calls a method if provided to return the name of the Salesforce object the model is syncing to.
          # If no method is provided, defaults to the class name
          def salesforce_object_name
            return send(self.class.salesforce_object_name_method) if self.class.salesforce_object_name_method.present?
            self.class.name
          end

          # Calls a method, if provided, to determine if a record should be synced to Salesforce.
          # The salesforce_skip_sync instance variable is also used.
          # The SALESFORCE_AR_SYNC_ENABLED flag overrides all the others if set to false
          def salesforce_skip_sync?
            return true if SalesforceArSync.config['SYNC_ENABLED'] == false
            return (salesforce_skip_sync || !self.class.salesforce_sync_enabled || send(self.class.salesforce_skip_sync_method)) if self.class.salesforce_skip_sync_method.present?
            (salesforce_skip_sync || !self.class.salesforce_sync_enabled)
          end
        end
      end
    end
  end
end
