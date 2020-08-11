require 'active_support/concern'

module SalesforceArSync
  module SalesforceSync
    extend ActiveSupport::Concern

    module ClassMethods
      # Optionally holds the value to determine if salesforce syncing is enabled. Defaults to true. If set
      # to false syncing will be disabled for the class
      attr_accessor :salesforce_sync_enabled

      # Hash mapping of Salesforce attributes to web attributes
      # Example:
      # { :Email => :login, :FirstName => :first_name, :LastName => :last_name }
      #
      # "Web" attributes can be actual method names to return a custom value
      # If you are providing a method name to return a value, you should also implement a corresponding my_method_changed? to
      # return if the value has changed.  Otherwise it will always be synced.
      attr_accessor :salesforce_sync_attribute_mapping

      # Returns an array of Salesforce attributes which should be synced asynchronously
      # Example:  ["Last_Login_Date__c", "Login_Count__c" ]
      # Note:  The model will fall back to synchronous sync if non-synchronous attributes are changed along with async attributes
      attr_accessor :salesforce_async_attributes

      # Returns a hash of default attributes that should be used when we are creating a new record
      attr_accessor :salesforce_default_attributes_for_create

      # Returns the "Id" attribute of the corresponding Salesforce object
      attr_accessor :salesforce_id_attribute_name

      # Returns the name of the Web Objects class. A custom value can be provided if you wish
      # to sync to a SF object and back to a different web object.  This would generally be used
      # if you wanted to flatten a web object into a larger SF object like Contact
      attr_accessor :salesforce_web_class_name

      # Specify whether or not we sync deletes inbound from salesforce or outbound from this app
      # Accepts either a true/false or a symbol to a method to be called
      attr_accessor :sync_inbound_delete
      attr_accessor :sync_outbound_delete

      # Specify whether we should use an unscoped find to update an object (useful with paranoia gem to handle undeletes)
      attr_accessor :unscoped_updates

      attr_accessor :salesforce_web_id_attribute_name
      attr_accessor :salesforce_sync_web_id
      attr_accessor :activerecord_web_id_attribute_name

      # Optionally can specify what fields can be used for finding the object that should be updated
      attr_accessor :additional_lookup_fields

      # Optionally holds the name of a method which will return the name of the Salesforce object to sync to
      attr_accessor :salesforce_object_name_method

      # Optionally holds the name of a method which can contain logic to determine if a record should be synced on save.
      # If no method is given then only the salesforce_skip_sync attribute is used.
      attr_accessor :salesforce_skip_sync_method

      # Optionally holds the name of a method which can provide custom logic for saving a record
      # If no method is given then `ActiveRecord::Base#save!` is used
      attr_accessor :salesforce_save_method

      # Accepts values from an outbound message hash and will either update an existing record OR create a new record
      # Firstly attempts to find an object by the salesforce_id attribute
      # Secondly attempts to look an object up by it's ID (WebId__c in outbound message)
      # Lastly it will create a new record setting it's salesforce_id
      def salesforce_update(attributes = {})
        raise ArgumentError, "#{salesforce_id_attribute_name} parameter required" if attributes[salesforce_id_attribute_name].blank?
        data_source = unscoped_updates ? unscoped : self
        object = data_source.find_by(salesforce_id: attributes[salesforce_id_attribute_name])
        object ||= data_source.find_by(activerecord_web_id_attribute_name => attributes[salesforce_web_id_attribute_name]) if salesforce_sync_web_id? && attributes[salesforce_web_id_attribute_name]

        if !object && additional_lookup_fields
          additional_lookup_fields.each do |attribute_name, salesforce_attribute_name|
            object = data_source.find_by(attribute_name => attributes[salesforce_attribute_name]) if attributes[salesforce_attribute_name]
          end
        end

        if object.nil?
          object = new
          salesforce_default_attributes_for_create.merge(salesforce_id: attributes[salesforce_id_attribute_name]).each_pair do |k, v|
            object.send("#{k}=", v)
          end
        end

        object.salesforce_process_update(attributes) if object && (object.salesforce_updated_at.nil? || (object.salesforce_updated_at && object.salesforce_updated_at < Time.parse(attributes[:SystemModstamp])))
      end
    end

    # if this instance variable is set to true, the salesforce_sync method will return without attempting
    # to sync data to Salesforce
    attr_accessor :salesforce_skip_sync

    # Salesforce completely excludes any empty/null fields from Outbound Messages
    # We initialize all declared attributes as nil before mapping the values from the message
    def salesforce_empty_attributes
      {}.tap do |hash|
        self.class.salesforce_sync_attribute_mapping.each do |key, _value|
          hash[key] = nil
        end
      end
    end

    # An internal method used to get a hash of values that we are going to set from a Salesforce outbound message hash
    def salesforce_attributes_to_set(attributes = {})
      {}.tap do |hash|
        # loop through the hash of attributes from the outbound message, and compare to our sf mappings and
        # create a reversed hash of value's and key's to pass to update_attributes
        attributes.each do |key, value|
          # make sure our sync_mapping contains the salesforce attribute AND that our object has a setter for it
          hash[self.class.salesforce_sync_attribute_mapping[key.to_s].to_sym] = value if self.class.salesforce_sync_attribute_mapping.include?(key.to_s) && respond_to?("#{self.class.salesforce_sync_attribute_mapping[key.to_s]}=")
        end

        # remove the web_id from hash if it exists, as we don't want to modify a web_id
        hash.delete(:id) if hash[:id]

        # update the sf_updated_at field with the system mod stamp from sf
        hash[:salesforce_updated_at] = attributes[:SystemModstamp]

        # incase we looked up via the WebId__c, we should set the salesforce_id
        hash[:salesforce_id] = attributes[self.class.salesforce_id_attribute_name]
      end
    end

    # Gets passed the Salesforce outbound message hash of changed values and updates the corresponding model
    def salesforce_process_update(attributes = {})
      attributes_to_update = salesforce_attributes_to_set(new_record? ? attributes : salesforce_empty_attributes.merge(attributes)) # only merge empty attributes for updates, so we don't overwrite the default create attributes
      attributes_to_update.each_pair do |k, v|
        send("#{k}=", v)
      end

      # we don't want to keep going in a endless loop.  SF has just updated these values.
      self.salesforce_skip_sync = true
      self.send(self.class.salesforce_save_method)
    end

    #    def salesforce_object_exists?
    #      return salesforce_object_exists_method if respond_to? salesforce_exists_method
    #      return salesforce_object_exists_default
    #    end

    # Finds a salesforce record by its Id and returns nil or its SystemModstamp
    def system_mod_stamp
      hash = JSON.parse(SF_CLIENT.http_get("/services/data/v#{SF_CLIENT.version}/query", q: "SELECT SystemModstamp FROM #{salesforce_object_name} WHERE Id = '#{salesforce_id}'").body)
      hash['records'].first.try(:[], 'SystemModstamp')
    end

    def salesforce_object_exists?
      return @exists_in_salesforce if @exists_in_salesforce
      @exists_in_salesforce = !system_mod_stamp.nil?
    end

    # Checks if the passed in attribute should be updated in Salesforce.com
    def salesforce_should_update_attribute?(attribute)
      !respond_to?("#{attribute}_changed?") || (respond_to?("#{attribute}_changed?") && send("#{attribute}_changed?"))
    end

    # create a hash of updates to send to salesforce
    def salesforce_attributes_to_update(include_all = false)
      {}.tap do |hash|
        self.class.salesforce_sync_attribute_mapping.each do |key, value|
          next unless respond_to?(value)

          # Checkboxes in SFDC Cannot be nil.  Here we check for boolean field type and set nil values to be false
          attribute_value = send(value)
          attribute_value = false if is_boolean?(value) && attribute_value.nil?

          hash[key] = attribute_value if include_all || salesforce_should_update_attribute?(value)
        end
      end
    end

    def is_boolean?(attribute)
      column_for_attribute(attribute) && column_for_attribute(attribute).type == :boolean
    end

    def salesforce_create_object(attributes)
      attributes[self.class.salesforce_web_id_attribute_name.to_s] = id if self.class.salesforce_sync_web_id? && !new_record?
      result = SF_CLIENT.http_post("/services/data/v#{SF_CLIENT.version}/sobjects/#{salesforce_object_name}", format_attributes(attributes).to_json)
      self.salesforce_id = JSON.parse(result.body)['id']
      @exists_in_salesforce = true
    end

    def salesforce_update_object(attributes)
      attributes[self.class.salesforce_web_id_attribute_name.to_s] = id if self.class.salesforce_sync_web_id? && !new_record?
      SF_CLIENT.http_patch("/services/data/v#{SF_CLIENT.version}/sobjects/#{salesforce_object_name}/#{salesforce_id}", format_attributes(attributes).to_json)
    end

    def salesforce_delete_object
      if ar_sync_outbound_delete?
        SF_CLIENT.http_delete("/services/data/v#{SF_CLIENT.version}/sobjects/#{salesforce_object_name}/#{salesforce_id}")
      end
    end

    # Check to see if the user passed in a true/false, if so return that, if not then they passed int a symbol to a method
    # We then call the method and use its value instead
    def ar_sync_inbound_delete?
      [true, false].include?(self.class.sync_inbound_delete) ? self.class.sync_inbound_delete : send(self.class.sync_inbound_delete)
    end

    def ar_sync_outbound_delete?
      [true, false].include?(self.class.sync_outbound_delete) ? self.class.sync_outbound_delete : send(self.class.sync_outbound_delete)
    end

    # if attributes specified in the async_attributes array are the only attributes being modified, then sync the data
    # via delayed_job
    def salesforce_perform_async_call?
      return false if salesforce_attributes_to_update.empty? || self.class.salesforce_async_attributes.empty?
      salesforce_attributes_to_update.keys.all? { |key| self.class.salesforce_async_attributes.include?(key) } && salesforce_id.present?
    end

    # sync model data to Salesforce, adding any Salesforce validation errors to the models errors
    def salesforce_sync
      return if salesforce_skip_sync?
      if salesforce_perform_async_call?
        Delayed::Job.enqueue(SalesforceArSync::SalesforceObjectSync.new(self.class.salesforce_web_class_name, salesforce_id, salesforce_attributes_to_update), priority: 50)
      else
        if salesforce_object_exists?
          salesforce_update_object(salesforce_attributes_to_update) if salesforce_attributes_to_update.present?
        else
          salesforce_create_object(salesforce_attributes_to_update(!new_record?)) if salesforce_id.nil?
        end
      end
    rescue Exception => ex
      errors[:base] << ex.message
      return false
    end

    def sync_web_id
      return false if !self.class.salesforce_sync_web_id?
      SF_CLIENT.http_patch("/services/data/v#{SF_CLIENT.version}/sobjects/#{salesforce_object_name}/#{salesforce_id}", { self.class.salesforce_web_id_attribute_name.to_s => get_activerecord_web_id }.to_json) if salesforce_id
    end

    def get_activerecord_web_id
      send(self.class.activerecord_web_id_attribute_name)
    end

    private

    # Multi-picklists in the SF Rest API are expected to be in a semicolon separated list
    # This method converts all attribute that are arrays into these values
    # Eg. ["A","B","C"]  =>  "A;B;C"
    def format_attributes(attributes)
      attributes.each do |k, v|
        attributes[k] = v.join(';') if v.is_a?(Array)
      end
      attributes
    end
  end
end
