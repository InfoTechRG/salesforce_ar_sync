require 'spec_helper.rb'

# for testing our environment variables
SalesforceArSync.config = {}
SalesforceArSync.config['ORGANIZATION_ID'] = '123456789123456789'
SalesforceArSync.config['SYNC_ENABLED'] = true
SalesforceArSync.config['DELETION_MAP'] = { 'Account' => 'Vendor' }

delete_hsh = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '003A0000014dbEeIAI',
  Object_Type__c: 'Account'
}

delete_hsh_without_id = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '',
  Object_Type__c: 'Account'
}

delete_hsh_without_type = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '003A0000014dbEeIAI',
  Object_Type__c: ''
}

delete_hsh_with_unknown_type = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '003A0000014dbEeIAI',
  Object_Type__c: 'Unknown'
}

# Actually maps to Account
class Vendor < ActiveRecord::Base
  salesforce_syncable sync_attributes: { Name: :name, salesforce_object_name: :Account }
end

describe SalesforceArSync::SoapHandler::Delete do
  describe 'self.delete_object' do
    it 'should raise an argument error if missing the object id' do
      expect { SalesforceArSync::SoapHandler::Delete.delete_object(delete_hsh_without_id) }.to raise_error(ArgumentError)
    end

    it 'should raise an argument error if missing the object type' do
      expect { SalesforceArSync::SoapHandler::Delete.delete_object(delete_hsh_without_type) }.to raise_error(ArgumentError)
    end

    it 'should raise an exception if the class can\'t be found' do
      expect { SalesforceArSync::SoapHandler::Delete.delete_object(delete_hsh_with_unknown_type) }.to raise_error(Exception)
    end

    it 'should delete a Vendor' do
      Vendor.create(name: 'Test Inc.', salesforce_skip_sync: true, salesforce_id: '003A0000014dbEeIAI')
      expect { SalesforceArSync::SoapHandler::Delete.delete_object(delete_hsh) }.to change { Vendor.all.size }.by(-1)
    end

    it 'should not fail if the object can\'t be found' do
      Vendor.create(name: 'Test Inc.', salesforce_skip_sync: true, salesforce_id: '003A0000014dbEeIAL')
      expect { SalesforceArSync::SoapHandler::Delete.delete_object(delete_hsh) }.to_not change { Vendor.all.size }
    end
  end
end
