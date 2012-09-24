require 'spec_helper.rb'

#for testing our environment variables
SalesforceArSync.config = Hash.new
SalesforceArSync.config["ORGANIZATION_ID"] = "123456789123456789"
SalesforceArSync.config["SYNC_ENABLED"] = true

class Contact < SuperModel::Base
  include ActiveModel::Validations::Callbacks
  extend SalesforceArSync::Extenders::SalesforceSyncable

  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone_number, :Email => :email_address}

  attributes :first_name, :last_name, :phone, :email, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name
  
  def phone_number=(new_phone_number)
    self.phone = new_phone_number
  end
  
  def email_address
    self.email
  end
  
  def email_address_changed?
    email_changed?
  end
  
  # Hack for SuperModel to allow setting all attributes
  def attributes=(attributes={})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  # Hack for SuperModel to convert string to Time
  def salesforce_updated_at=(updated_at)
    updated_at = Time.parse(updated_at) if updated_at.present? && updated_at.kind_of?(String)
    write_attribute(:salesforce_updated_at, updated_at)
  end
  
  # Hack for SuperModel, since we don't have any actually DB columns, we need to override the is_boolean?(attr) method
  def is_boolean?(attribute)
    %w().include?(attribute)
  end
end

# the following hash should match the data in SF.com you are testing against
sample_outbound_message_hash = {
  :Id => '003A0000014dbEeIAI',
  :FirstName => 'Rose',
  :LastName => 'Gonzalez',
  :Phone => '(512) 757-6000',
  :SystemModstamp => '2012-03-26T19:54:50.000Z',
  :WebId__c => 68836
}

# this message is missing the Phone field on purpose
# Salesforce does not include empty fields  in the body
# of an outbound message
sample_partial_outbound_message_hash = {
  :Id => '003A0000014dbEeIAI',
  :FirstName => 'Rose',
  :LastName => 'Gonzalez',
  :SystemModstamp => '2012-03-26T19:54:50.000Z',
  :WebId__c => 68836
}

describe SalesforceArSync, :vcr do
  describe 'salesforce_syncable' do
    class TestSyncable < SuperModel::Base
      include ActiveModel::Validations::Callbacks
      extend SalesforceArSync::Extenders::SalesforceSyncable

      salesforce_syncable :salesforce_sync_enabled => false,
        :sync_attributes => {:FirstName => :first_name, :LastName => :last_name},
        :async_attributes => ["Last_Login__c", "Login_Count__c"],
        :default_attributes_for_create => {:password_change_required => true},
        :salesforce_id_attribute_name => :Id,
        :web_id_attribute_name  => :WebId__c,
        :salesforce_sync_web_id => false,
        :web_class_name => 'Contact',
        :salesforce_object_name => :salesforce_object_name_method_name,
        :salesforce_object => :salesforce_object_method_name,
        :except => :except_method_name
    end
    
    it 'should assign values from the options hash to model attributes' do
      TestSyncable.salesforce_sync_enabled.should eq(false)
      TestSyncable.salesforce_sync_attribute_mapping.should eq({"FirstName" => :first_name, "LastName" => :last_name})
      TestSyncable.salesforce_async_attributes.should eq(["Last_Login__c", "Login_Count__c"])
      TestSyncable.salesforce_default_attributes_for_create.should eq({:password_change_required => true})
      TestSyncable.salesforce_id_attribute_name.should eq(:Id)
      TestSyncable.salesforce_web_id_attribute_name.should eq(:WebId__c)
      TestSyncable.salesforce_web_class_name.should eq("Contact")
      TestSyncable.salesforce_object_name_method.should eq(:salesforce_object_name_method_name)
      TestSyncable.salesforce_object_method.should eq(:salesforce_object_method_name)
      TestSyncable.salesforce_skip_sync_method.should eq(:except_method_name)
    end
  end

  describe 'sync_web_id' do
    it 'returns false if salesforce_skip_sync? is true' do
      Contact.any_instance.stub(:salesforce_skip_sync?).and_return(true)
      Contact.stub!(:salesforce_sync_web_id?).and_return(true)
            
      Contact.new.sync_web_id.should eq(false)
    end
  end
  
  describe '.salesforce_update' do
    it 'should raise an exception if the salesforce id is blank' do
      lambda { Contact.salesforce_update(:Id => '', :FirstName => 'Bob') }.should raise_exception(ArgumentError)
      lambda { Contact.salesforce_update(:FirstName => 'Bob')}.should raise_exception(ArgumentError)
    end
  end  
    
  describe '.salesforce_id_attribute_name' do
    it "returns the salesforce Id attribute name" do
      Contact.salesforce_id_attribute_name.should == :Id
    end
  end
  
  describe '.salesforce_sync_web_id?' do
    it "should default to false" do
      Contact.salesforce_sync_web_id?.should be_false
    end
  end
  
  describe '.salesforce_web_id_attribute_name' do
    it "should default to 'WebId__c'" do
      Contact.salesforce_web_id_attribute_name.should == :WebId__c
    end
  end
  
  describe '.salesforce_default_attributes_for_create' do
    it "should default to an empty hash" do
      Contact.salesforce_default_attributes_for_create.should == {}
    end
  end

  describe '#salesforce_object_name' do
    it "returns the current class name" do
      Contact.new.salesforce_object_name.should == "Contact"
    end
    
    it "calls a method if one is provided" do
      class User < SuperModel::Base
        include ActiveModel::Validations::Callbacks
        extend SalesforceArSync::Extenders::SalesforceSyncable

        salesforce_syncable :salesforce_object_name => :custom_name
        
        def custom_name
          "CustomUser"
        end
      end
      
      user = User.new
      user.salesforce_object_name.should eq("CustomUser")
    end
  end
  
  describe 'salesforce_skip_sync?' do
    context 'by default' do
      it 'should return false' do
        Contact.new.salesforce_skip_sync?.should be_false
      end
    end

    context 'when SYNC_ENABLED is false in the global SalesforceArSync.config hash' do
      it 'should return true' do
        SalesforceArSync.config["SYNC_ENABLED"] = false;

        Contact.new.salesforce_skip_sync?.should be_true

        SalesforceArSync.config["SYNC_ENABLED"] = true;
      end
    end

    context 'when salesforce_skip_sync is true on an object' do
      it 'returns true' do
        contact = Contact.new(:salesforce_skip_sync => true)
        
        contact.salesforce_skip_sync?.should be_true
      end
    end

    context 'when salesforce_sync_enabled is false on a class it' do
      it 'returns true' do
        class SyncTest < SuperModel::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :salesforce_sync_enabled => false
        end
        
        sync_test = SyncTest.new
        sync_test.salesforce_skip_sync?.should be_true
      end

      it 'returns true if salesforce_skip_sync is set to true on an object' do
        class SyncTest < SuperModel::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :salesforce_sync_enabled => false
        end
        
        sync_test = SyncTest.new(:salesforce_skip_sync => true)
        sync_test.salesforce_skip_sync?.should be_true
      end
    end
    
    context 'when given a method' do      
      it 'returns the methods value' do
        class SyncTest < SuperModel::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :except => :custom_sync

          def custom_sync
            return true
          end
        end
        
        sync_test = SyncTest.new
        sync_test.salesforce_skip_sync?.should be_true
      end

      it 'returns true if salesforce_sync_enabled is set to false on a class' do
        class SyncTest < SuperModel::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :except => :custom_sync, :salesforce_sync_enabled => false

          def custom_sync
            return false
          end
        end
        
        sync_test = SyncTest.new()
        sync_test.salesforce_skip_sync?.should be_true
      end
      
      it 'returns true if salesforce_skip_sync is set to true on an object' do
        class SyncTest < SuperModel::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :except => :custom_sync

          def custom_sync
            return false
          end
        end
        
        sync_test = SyncTest.new(:salesforce_skip_sync => true)
        sync_test.salesforce_skip_sync?.should be_true
      end
    end
  end
  
  describe '#salesforce_object' do
    before(:each) do
      $sf_client = Databasedotcom::Client.new(:host => 'login.salesforce.com', :client_id => '', :client_secret => '')
      $sf_client.authenticate :username => '', :password => ''
      $sf_client.sobject_module = Databasedotcom
      $sf_client.materialize "Contact"  
    end
    
    context 'given we have a salesforce id' do
      it 'finds and returns the salesforce object by the salesforce_id' do
        contact = Contact.new(:salesforce_id => sample_outbound_message_hash[:Id])
        contact.salesforce_object.FirstName.should == sample_outbound_message_hash[:FirstName]
      end
    end
    
    context 'given we have no salesforce id and are not syncing the web id' do
      it "returns nil" do
        contact = Contact.new(:salesforce_id => nil)
        contact.salesforce_object.should be_nil
      end
    end
    
    context 'given we have no salesforce id and we are syncing the web id' do
      it 'finds and returns the salesforce object by the WebId__c' do
        Databasedotcom::Contact.upsert("Id", sample_outbound_message_hash[:Id], "WebId__c" => sample_outbound_message_hash[:WebId__c])
        
        Contact.stub(:salesforce_sync_web_id?).and_return(true)
        contact = Contact.new(:salesforce_id => nil)
        contact.salesforce_skip_sync = true
        contact.id = sample_outbound_message_hash[:WebId__c]
        contact.save!
        contact.salesforce_object.FirstName.should == sample_outbound_message_hash[:FirstName]
      end
    end
    
    context 'given we have a new record with no salesforce id' do
      it 'returns nil' do
        contact = Contact.new(:salesforce_id => nil)
        contact.salesforce_object.should be_nil
      end
    end
    
    context 'given the model has provided a custom method' do
      it 'executes the provided method' do
        class User < SuperModel::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :salesforce_object => :custom_salesforce_object

          def custom_salesforce_object
            "CustomUser"
          end
        end
        
        user = User.new
        user.salesforce_object.should eq("CustomUser")
      end
    end
  end
  
  describe '#salesforce_attributes_to_set' do
    
    before(:each) do
      @hash = Contact.new.salesforce_attributes_to_set(sample_outbound_message_hash)
    end
    
    it 'hash should include salesforce_updated_at' do
      @hash[:salesforce_updated_at].should == sample_outbound_message_hash[:SystemModstamp]
    end
    
    it 'hash should include salesforce_id' do
      @hash[:salesforce_id].should == sample_outbound_message_hash[:Id]
    end
    
    it 'hash should only include keys and values in the mapping that we have setters for' do
      @hash[:first_name].should == sample_outbound_message_hash[:FirstName]
      @hash[:last_name].should == sample_outbound_message_hash[:LastName]
      @hash[:phone_number].should == sample_outbound_message_hash[:Phone]
    end
    
    it 'hash should only include 5 keys' do
      @hash.keys.count.should == 5
    end
    
    it 'removes any attribute mapped to "id" as we do not want to set our primary key' do
      Contact.stub(:salesforce_sync_attribute_mapping).and_return({"WebId__c" => "Id"})
      contact = Contact.new
            
      contact.salesforce_attributes_to_set(sample_outbound_message_hash).tap do |hash|
        hash[:first_name].should be_nil
      end
    end
    
  end
  
  describe '#salesforce_process_update' do
    it 'should update and save record with values passed in to hash' do
      contact = Contact.new(:first_name => "Bob", :last_name => "Smith")
      contact.salesforce_skip_sync = true
      contact.save!
      contact.salesforce_process_update(sample_outbound_message_hash)
      
      contact.first_name.should == sample_outbound_message_hash[:FirstName]
      contact.last_name.should == sample_outbound_message_hash[:LastName]
      contact.phone.should == sample_outbound_message_hash[:Phone]
      contact.salesforce_id.should == sample_outbound_message_hash[:Id]
      contact.salesforce_updated_at.should == Time.parse(sample_outbound_message_hash[:SystemModstamp])
    end
    
    it 'should nil out any values not specified in the message from Salesforce' do
      contact = Contact.new(:first_name => "Bob", :last_name => "Smith", :phone => '5195556677')
      contact.salesforce_skip_sync = true
      contact.save!
      contact.salesforce_process_update(sample_partial_outbound_message_hash)
      
      contact.phone.should be_nil
      contact.first_name.should == sample_outbound_message_hash[:FirstName]
      contact.last_name.should == sample_outbound_message_hash[:LastName]
      contact.salesforce_id.should == sample_outbound_message_hash[:Id]
      contact.salesforce_updated_at.should == Time.parse(sample_outbound_message_hash[:SystemModstamp])
    end
  end
  
  describe '#salesforce_attributes_to_update' do
    context 'when passing include_all as true' do
      it 'returns a hash of all attributes and values included in mapping that have getter methods' do
        contact = Contact.create(:first_name => "Bob", :last_name => "Smith", :phone => "519 555-1212", :email => "bsmith@example.com", :salesforce_skip_sync => true)
        contact.first_name = "Bill"
        contact.salesforce_attributes_to_update(true).tap do |hash|
          hash["FirstName"].should == "Bill"
          hash["LastName"].should == "Smith"
          hash["Email"].should == "bsmith@example.com"
        end
      end
    end
    context 'when passing include_all as false' do
      it 'returns a hash of changed attributes and values included in mapping that have getter methods' do
        contact = Contact.create(:first_name => "Bob", :last_name => "Smith", :phone => "519 555-1212", :email => "bsmith@example.com", :salesforce_skip_sync => true)
        contact.first_name = "Bill"
        contact.salesforce_attributes_to_update(true).tap do |hash|
          hash["FirstName"].should == "Bill"
        end
      end
    end
  end  
end