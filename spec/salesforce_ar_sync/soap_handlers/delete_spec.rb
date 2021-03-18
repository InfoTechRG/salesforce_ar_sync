require 'spec_helper.rb'

# for testing our environment variables
SalesforceArSync.config = {}
SalesforceArSync.config['ORGANIZATION_ID'] = '123456789123456789'
SalesforceArSync.config['SYNC_ENABLED'] = false
SalesforceArSync.config['DELETION_MAP'] = { 'Account' => 'Vendor' }

DELETE_HSH = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '003A0000014dbEeIAI',
  Object_Type__c: 'Account'
}.freeze

CONTACT_DELETE_HSH = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '003A0000014dbEeIAI',
  Object_Type__c: 'Contact'
}.freeze

DELETE_HSH_WITHOUT_ID = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '',
  Object_Type__c: 'Account'
}.freeze

DELETE_HSH_WITHOUT_TYPE = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '003A0000014dbEeIAI',
  Object_Type__c: ''
}.freeze

DELETE_HSH_WITH_UNKNOWN_TYPE = {
  Id: '003A0000014dbEeIAJ',
  Object_Id__c: '003A0000014dbEeIAI',
  Object_Type__c: 'Unknown'
}.freeze

# Actually maps to Account
class Vendor < ActiveRecord::Base
  salesforce_syncable sync_attributes: { Name: :name, salesforce_object_name: :Account }
end

describe SalesforceArSync::SoapHandler::Delete do
  describe 'self.delete_object' do
    context 'with delete config' do
      before :each do
        SalesforceArSync.config = {}
        SalesforceArSync.config['ORGANIZATION_ID'] = '123456789123456789'
        SalesforceArSync.config['SYNC_ENABLED'] = false
        SalesforceArSync.config['DELETION_MAP'] = { 'Account' => 'Vendor' }
      end

      it 'should raise an argument error if missing the object id' do
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH_WITHOUT_ID) }.to raise_error(ArgumentError)
      end

      it 'should raise an argument error if missing the object type' do
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH_WITHOUT_TYPE) }.to raise_error(ArgumentError)
      end

      it 'should raise an exception if the class can\'t be found' do
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH_WITH_UNKNOWN_TYPE) }.to raise_error(Exception)
      end

      it 'should delete a Vendor' do
        Vendor.create(name: 'Test Inc.', salesforce_skip_sync: true, salesforce_id: '003A0000014dbEeIAI')
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH) }.to change { Vendor.all.size }.by(-1)
      end

      it 'should not fail if the object can\'t be found' do
        Vendor.create(name: 'Test Inc.', salesforce_skip_sync: true, salesforce_id: '003A0000014dbEeIAL')
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH) }.to_not change { Vendor.all.size }
      end
    end

    describe 'without delete config' do
      before :each do
        SalesforceArSync.config = {}
        SalesforceArSync.config['ORGANIZATION_ID'] = '123456789123456789'
        SalesforceArSync.config['SYNC_ENABLED'] = false
        SalesforceArSync.config['DELETION_MAP'] = {}
      end

      it 'should raise an argument error if missing the object id' do
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH_WITHOUT_ID) }.to raise_error(ArgumentError)
      end

      it 'should raise an argument error if missing the object type' do
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH_WITHOUT_TYPE) }.to raise_error(ArgumentError)
      end

      it 'should raise an exception if the class can\'t be found' do
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH_WITH_UNKNOWN_TYPE) }.to raise_error(Exception)
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(DELETE_HSH) }.to raise_error(Exception)
      end

      it 'should delete a contact' do
        Contact.create(first_name: 'Test', last_name: 'Test', salesforce_skip_sync: true, salesforce_id: '003A0000014dbEeIAI')
        expect { SalesforceArSync::SoapHandler::Delete.delete_object(CONTACT_DELETE_HSH) }.to change { Contact.all.size }.by(-1)
      end
    end
  end
end
