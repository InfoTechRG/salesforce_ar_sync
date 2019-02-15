require 'spec_helper.rb'

#for testing our environment variables
SalesforceArSync.config = Hash.new
SalesforceArSync.config["ORGANIZATION_ID"] = "123456789123456789"
SalesforceArSync.config["SYNC_ENABLED"] = true

class Contact < ActiveRecord::Base
  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone_number, :Email => :email_address}

  def phone_number=(new_phone_number)
    self.phone = new_phone_number
  end

  def email_address
    self.email
  end

  def email_address_changed?
    email_changed?
  end

  # Hack for Parsing into the proper Timezone
  def salesforce_updated_at=(updated_at)
    updated_at = Time.parse(updated_at) if updated_at.present? && updated_at.kind_of?(String)
    write_attribute(:salesforce_updated_at, updated_at)
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
    class TestSyncable < ActiveRecord::Base
      include ActiveModel::Validations::Callbacks
      extend SalesforceArSync::Extenders::SalesforceSyncable

      salesforce_syncable :salesforce_sync_enabled => false,
        :sync_attributes => {:FirstName => :first_name, :LastName => :last_name},
        :async_attributes => ["Last_Login__c", "Login_Count__c"],
        :default_attributes_for_create => {:password_change_required => true},
        :salesforce_id_attribute_name => :Id,
        :web_id_attribute_name  => :WebId__c,
        :activerecord_web_id_attribute_name => :web_id,
        :salesforce_sync_web_id => false,
        :web_class_name => 'Contact',
        :salesforce_object_name => :salesforce_object_name_method_name,
        :except => :except_method_name,
        :save_method => :save_method_name,
        :sync_inbound_delete => false,
        :sync_outbound_delete => :outbound_delete_method_name,
        :unscoped_updates => false,
        :additional_lookup_fields => {:login => :User_ID_Email__c}
    end

    it 'should assign values from the options hash to model attributes' do
      expect(TestSyncable.salesforce_sync_enabled).to eq(false)
      expect(TestSyncable.salesforce_sync_attribute_mapping).to eq({"FirstName" => :first_name, "LastName" => :last_name})
      expect(TestSyncable.salesforce_async_attributes).to eq(["Last_Login__c", "Login_Count__c"])
      expect(TestSyncable.salesforce_default_attributes_for_create).to eq({:password_change_required => true})
      expect(TestSyncable.salesforce_id_attribute_name).to eq(:Id)
      expect(TestSyncable.salesforce_web_id_attribute_name).to eq(:WebId__c)
      expect(TestSyncable.activerecord_web_id_attribute_name).to eq(:web_id)
      expect(TestSyncable.salesforce_web_class_name).to eq("Contact")
      expect(TestSyncable.salesforce_object_name_method).to eq(:salesforce_object_name_method_name)
      expect(TestSyncable.salesforce_skip_sync_method).to eq(:except_method_name)
      expect(TestSyncable.salesforce_save_method).to eq(:save_method_name)
      expect(TestSyncable.sync_inbound_delete).to eq(false)
      expect(TestSyncable.sync_outbound_delete).to eq(:outbound_delete_method_name)
      expect(TestSyncable.unscoped_updates).to eq(false)
      expect(TestSyncable.additional_lookup_fields).to eq({:login => :User_ID_Email__c})
    end
  end

  describe 'sync_web_id' do
    it 'returns false if salesforce_skip_sync? is true' do
      allow_any_instance_of(Contact).to receive(:salesforce_skip_sync?).and_return(true)
      allow(Contact).to receive(:salesforce_sync_web_id?).and_return(true)

      expect(Contact.new.sync_web_id).to eq(false)
    end
  end

  describe '.salesforce_update' do
    it 'should raise an exception if the salesforce id is blank' do
      expect { Contact.salesforce_update(:Id => '', :FirstName => 'Bob') }.to raise_exception(ArgumentError)
      expect { Contact.salesforce_update(:FirstName => 'Bob')}.to raise_exception(ArgumentError)
    end
    it 'looks for records matching salesforce id' do
      sf_id = 1

      allow(Contact).to receive(:salesforce_sync_web_id?).and_return(false)
      allow(Contact).to receive(:unscoped_updates?).and_return(false)

      expect(Contact).to receive(:find_by).with(salesforce_id: sf_id)
      Contact.salesforce_update(Id: sf_id)
    end
    it 'looks for records matching salesforce or web id' do
      sf_id = 1
      web_id = 20

      allow(Contact).to receive(:salesforce_sync_web_id?).and_return(true)
      allow(Contact).to receive(:unscoped_updates?).and_return(false)

      expect(Contact).to receive(:find_by).with(salesforce_id: sf_id)
      expect(Contact).to receive(:find_by).with(id: web_id)
      Contact.salesforce_update(Id: sf_id, WebId__c: web_id)
    end
    it 'looks for records matching salesforce id or with a custom field matching web id' do
      sf_id = 1
      web_id = 20

      allow(Contact).to receive(:salesforce_sync_web_id?).and_return(true)
      allow(Contact).to receive(:activerecord_web_id_attribute_name).and_return(:custom_web_id)
      allow(Contact).to receive(:custom_web_id).and_return(web_id)
      allow(Contact).to receive(:unscoped_updates?).and_return(false)

      expect(Contact).to receive(:find_by).with(salesforce_id: sf_id)
      expect(Contact).to receive(:find_by).with(custom_web_id: web_id)
      Contact.salesforce_update(Id: sf_id, WebId__c: web_id)
    end

    it 'looks for records by additional_lookup_fields when not found by SF id or web id', focus: true do
      allow(Contact).to receive(:salesforce_sync_web_id?).and_return(true)
      allow(Contact).to receive(:additional_lookup_fields).and_return({login: :User_ID_Email__c})

      expect(Contact).to receive(:find_by).with(salesforce_id: 1)
      expect(Contact).to receive(:find_by).with(id: 1)
      expect(Contact).to receive(:find_by).with(login: 'test@test.com')
      Contact.salesforce_update(Id: 1, WebId__c: 1, User_ID_Email__c: 'test@test.com')
    end

    it 'looks for unscoped records when unscoped_updates is set' do
      sf_id = 1
      contact = Contact.new(salesforce_id: sf_id)
      allow(Contact).to receive(:unscoped_updates).and_return(true)

      expect(contact).to receive(:salesforce_process_update) { nil }
      expect(Contact).to receive(:unscoped).and_return(self)
      expect(self).to receive(:find_by).with(salesforce_id: sf_id).and_return(contact)

      Contact.salesforce_update(Id: sf_id)
    end

  end

  describe '.salesforce_id_attribute_name' do
    it "returns the salesforce Id attribute name" do
      expect(Contact.salesforce_id_attribute_name).to eq(:Id)
    end
  end

  describe '.salesforce_sync_web_id?' do
    it "should default to false" do
      expect(Contact.salesforce_sync_web_id?).to be_falsey
    end
  end

  describe '.salesforce_web_id_attribute_name' do
    it "should default to 'WebId__c'" do
      expect(Contact.salesforce_web_id_attribute_name).to eq(:WebId__c)
    end
  end

  describe '.salesforce_default_attributes_for_create' do
    it "should default to an empty hash" do
      expect(Contact.salesforce_default_attributes_for_create).to eq({})
    end
  end

  describe '#salesforce_object_name' do
    it "returns the current class name" do
      expect(Contact.new.salesforce_object_name).to eq("Contact")
    end

    it "calls a method if one is provided" do
      class User < ActiveRecord::Base
        include ActiveModel::Validations::Callbacks
        extend SalesforceArSync::Extenders::SalesforceSyncable

        salesforce_syncable :salesforce_object_name => :custom_name

        def custom_name
          "CustomUser"
        end
      end

      user = User.new
      expect(user.salesforce_object_name).to eq("CustomUser")
    end
  end

  describe '.ar_sync_inbound_delete?' do
    context 'by default' do
      it 'should return true' do
        contact = Contact.new

        expect(contact.ar_sync_inbound_delete?).to be_truthy
      end
    end

    context 'sync_inbound_delete set to true' do
      it 'should return true' do
        contact = Contact.new(:sync_inbound_delete => true)

        expect(contact.ar_sync_inbound_delete?).to be_truthy
      end
    end

    context 'sync_inbound_delete set to :method_name' do
      it 'should return the result of the method' do
        class DeleteTest < ActiveRecord::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :sync_inbound_delete => :sync_delete

          def sync_delete
            return true
          end
        end

        delete_test = DeleteTest.new
        expect(delete_test.ar_sync_inbound_delete?).to be_truthy
      end
    end
  end

  describe '.ar_sync_outbound_delete?' do
    context 'by default' do
      it 'should return false' do
        contact = Contact.new

        expect(contact.ar_sync_outbound_delete?).to be_falsey
      end
    end

    context 'sync_outbound_delete set to false' do
      it 'should return false' do
        contact = Contact.new(:sync_outbound_delete => false)

        expect(contact.ar_sync_outbound_delete?).to be_falsey
      end
    end

    context 'sync_outbound_delete set to :method_name' do
      it 'should return the result of the method' do
        class DeleteTest < ActiveRecord::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :sync_outbound_delete => :sync_delete

          def sync_delete
            return false
          end
        end

        delete_test = DeleteTest.new
        expect(delete_test.ar_sync_outbound_delete?).to be_falsey
      end
    end
  end

  describe 'salesforce_skip_sync?' do
    context 'by default' do
      it 'should return false' do
        expect(Contact.new.salesforce_skip_sync?).to be_falsey
      end
    end

    context 'when SYNC_ENABLED is false in the global SalesforceArSync.config hash' do
      it 'should return true' do
        SalesforceArSync.config["SYNC_ENABLED"] = false;

        expect(Contact.new.salesforce_skip_sync?).to be_truthy

        SalesforceArSync.config["SYNC_ENABLED"] = true;
      end
    end

    context 'when salesforce_skip_sync is true on an object' do
      it 'returns true' do
        contact = Contact.new(:salesforce_skip_sync => true)

        expect(contact.salesforce_skip_sync?).to be_truthy
      end
    end

    context 'when salesforce_sync_enabled is false on a class it' do
      it 'returns true' do
        class SyncTest < ActiveRecord::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :salesforce_sync_enabled => false
        end

        sync_test = SyncTest.new
        expect(sync_test.salesforce_skip_sync?).to be_truthy
      end

      it 'returns true if salesforce_skip_sync is set to true on an object' do
        class SyncTest < ActiveRecord::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :salesforce_sync_enabled => false
        end

        sync_test = SyncTest.new(:salesforce_skip_sync => true)
        expect(sync_test.salesforce_skip_sync?).to be_truthy
      end
    end

    context 'when given a method' do
      it 'returns the methods value' do
        class SyncTest < ActiveRecord::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :except => :custom_sync

          def custom_sync
            return true
          end
        end

        sync_test = SyncTest.new
        expect(sync_test.salesforce_skip_sync?).to be_truthy
      end

      it 'returns true if salesforce_sync_enabled is set to false on a class' do
        class SyncTest < ActiveRecord::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :except => :custom_sync, :salesforce_sync_enabled => false

          def custom_sync
            return false
          end
        end

        sync_test = SyncTest.new()
        expect(sync_test.salesforce_skip_sync?).to be_truthy
      end

      it 'returns true if salesforce_skip_sync is set to true on an object' do
        class SyncTest < ActiveRecord::Base
          include ActiveModel::Validations::Callbacks
          extend SalesforceArSync::Extenders::SalesforceSyncable

          salesforce_syncable :except => :custom_sync

          def custom_sync
            return false
          end
        end

        sync_test = SyncTest.new(:salesforce_skip_sync => true)
        expect(sync_test.salesforce_skip_sync?).to be_truthy
      end
    end
  end

  describe '#salesforce_attributes_to_set' do

    before(:each) do
      @hash = Contact.new.salesforce_attributes_to_set(sample_outbound_message_hash)
    end

    it 'hash should include salesforce_updated_at' do
      expect(@hash[:salesforce_updated_at]).to eq(sample_outbound_message_hash[:SystemModstamp])
    end

    it 'hash should include salesforce_id' do
      expect(@hash[:salesforce_id]).to eq(sample_outbound_message_hash[:Id])
    end

    it 'hash should only include keys and values in the mapping that we have setters for' do
      expect(@hash[:first_name]).to eq(sample_outbound_message_hash[:FirstName])
      expect(@hash[:last_name]).to eq(sample_outbound_message_hash[:LastName])
      expect(@hash[:phone_number]).to eq(sample_outbound_message_hash[:Phone])
    end

    it 'hash should only include 5 keys' do
      expect(@hash.keys.count).to eq(5)
    end

    it 'removes any attribute mapped to "id" as we do not want to set our primary key' do
      allow(Contact).to receive(:salesforce_sync_attribute_mapping).and_return({"WebId__c" => "Id"})
      contact = Contact.new

      contact.salesforce_attributes_to_set(sample_outbound_message_hash).tap do |hash|
        expect(hash[:first_name]).to be_nil
      end
    end

  end

  describe '#salesforce_process_update' do
    it 'should update and save record with values passed in to hash' do
      contact = Contact.new(:first_name => "Bob", :last_name => "Smith")
      contact.salesforce_skip_sync = true
      contact.save!
      contact.salesforce_process_update(sample_outbound_message_hash)

      expect(contact.first_name).to eq(sample_outbound_message_hash[:FirstName])
      expect(contact.last_name).to eq(sample_outbound_message_hash[:LastName])
      expect(contact.phone).to eq(sample_outbound_message_hash[:Phone])
      expect(contact.salesforce_id).to eq(sample_outbound_message_hash[:Id])
      expect(contact.salesforce_updated_at).to eq(Time.parse(sample_outbound_message_hash[:SystemModstamp]))
    end

    it 'should nil out any values not specified in the message from Salesforce' do
      contact = Contact.new(:first_name => "Bob", :last_name => "Smith", :phone => '5195556677')
      contact.salesforce_skip_sync = true
      contact.save!
      contact.salesforce_process_update(sample_partial_outbound_message_hash)

      expect(contact.phone).to be_nil
      expect(contact.first_name).to eq(sample_outbound_message_hash[:FirstName])
      expect(contact.last_name).to eq(sample_outbound_message_hash[:LastName])
      expect(contact.salesforce_id).to eq(sample_outbound_message_hash[:Id])
      expect(contact.salesforce_updated_at).to eq(Time.parse(sample_outbound_message_hash[:SystemModstamp]))
    end

    it 'should save with #save! if no save_method is given' do
      class ProcessUpdateTest < ActiveRecord::Base
        include ActiveModel::Validations::Callbacks
        extend SalesforceArSync::Extenders::SalesforceSyncable
        salesforce_syncable
      end

      process_update_test = ProcessUpdateTest.new
      expect(process_update_test).to receive(:save!)
      process_update_test.salesforce_process_update
    end

    it 'should use save with the value of save_method if it is provided' do
      class ProcessUpdateTest < ActiveRecord::Base
        include ActiveModel::Validations::Callbacks
        extend SalesforceArSync::Extenders::SalesforceSyncable

        salesforce_syncable :save_method => :save_method_name
      end

      process_update_test = ProcessUpdateTest.new
      expect(process_update_test).to receive(:save_method_name)
      process_update_test.salesforce_process_update
    end
  end

  describe '#salesforce_attributes_to_update' do
    context 'when passing include_all as true' do
      it 'returns a hash of all attributes and values included in mapping that have getter methods' do
        contact = Contact.create(:first_name => "Bob", :last_name => "Smith", :phone => "519 555-1212", :email => "bsmith@example.com", :salesforce_skip_sync => true)
        contact.first_name = "Bill"
        contact.salesforce_attributes_to_update(true).tap do |hash|
          expect(hash["FirstName"]).to eq("Bill")
          expect(hash["LastName"]).to eq("Smith")
          expect(hash["Email"]).to eq("bsmith@example.com")
        end
      end
    end
    context 'when passing include_all as false' do
      it 'returns a hash of changed attributes and values included in mapping that have getter methods' do
        contact = Contact.create(:first_name => "Bob", :last_name => "Smith", :phone => "519 555-1212", :email => "bsmith@example.com", :salesforce_skip_sync => true)
        contact.first_name = "Bill"
        contact.salesforce_attributes_to_update(true).tap do |hash|
          expect(hash["FirstName"]).to eq("Bill")
        end
      end
    end
  end
  describe '#get_activerecord_web_id' do
    context 'no custom web id' do
      it 'returns the id' do
        contact = Contact.new(id: 1)
        expect(contact.get_activerecord_web_id).to eq 1
      end
    end
    context 'custom web id' do
      it 'returns the id' do
        contact = Contact.new(id: 1, last_name: "Johnson")
        allow(Contact).to receive(:salesforce_sync_web_id?).and_return(true)
        allow(Contact).to receive(:activerecord_web_id_attribute_name).and_return(:last_name)

        expect(contact.get_activerecord_web_id).to eq "Johnson"
      end
    end
  end
end
