require 'spec_helper'
require 'rails/generators'
require 'generators/salesforce_ar_sync/configuration/configuration_generator'

describe SalesforceArSync::Generators::ConfigurationGenerator do
  destination File.expand_path("../../../../../tmp", __FILE__)

  before do
    prepare_destination
  end

  it 'should run the create_yaml task' do
    gen = generator
    gen.should_receive :create_yaml
    capture(:stdout) {gen.invoke_all}
  end
  
  describe 'creating a single YAML file with the defaults' do
    subject { file('config/salesforce_ar_sync.yml') }
    
    before  { run_generator }
    
    it { should contain "organization_id: #18 character organization_id" }
    it { should contain "sync_enabled: true" }
  end

  describe 'creating a single YAML file with an organization id' do
    subject { file('config/salesforce_ar_sync.yml') }
    
    before  { run_generator %w{123456789123456789} }

    it { should contain "organization_id: 123456789123456789" }
    it { should contain "sync_enabled: true" }
  end
end