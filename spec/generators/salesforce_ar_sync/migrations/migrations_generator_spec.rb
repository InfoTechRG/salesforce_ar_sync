require 'spec_helper'
require 'rails/generators'
require 'generators/salesforce_ar_sync/migrations/migrations_generator'

describe SalesforceArSync::Generators::MigrationsGenerator do
  destination File.expand_path("../../../../../tmp", __FILE__)

  before do
    prepare_destination
  end

  it 'should run the create_migrations task' do
    gen = generator %w(Model1)
    gen.should_receive :create_migrations
    capture(:stdout) {gen.invoke_all}
  end
  
  it 'should run the run_migrations task' do
    gen = generator %w(Contact --migrate)
    gen.should_receive :run_migrations
    capture(:stdout) {gen.invoke_all}
  end
  
  it 'should throw an exception with no arguments given' do
    lambda { run_generator }.should raise_exception(Thor::RequiredArgumentMissingError)  
  end
  
  describe 'creating a single migration' do
    subject { file('db/migrate/add_salesforce_fields_to_accounts.rb') }
    before  { run_generator %w(Account) }
    it { should be_a_migration }
  end
  
  describe 'creating multiple migrations' do
    before  { run_generator %w(Account Contact) }
    
    subject { file('db/migrate/add_salesforce_fields_to_accounts.rb') }
    it { should be_a_migration }
    
    subject { file('db/migrate/add_salesforce_fields_to_contacts.rb') }
    it { should be_a_migration }    
  end
end