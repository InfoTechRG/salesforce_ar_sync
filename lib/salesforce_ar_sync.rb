require 'salesforce_ar_sync/engine'
require 'salesforce_ar_sync/version'
require 'salesforce_ar_sync/extenders/salesforce_syncable'
require 'salesforce_ar_sync/soap_handler/base'
require 'salesforce_ar_sync/soap_handler/delete'
require 'salesforce_ar_sync/ip_constraint'
require 'salesforce_ar_sync/jobs/base_job'
require 'salesforce_ar_sync/jobs/salesforce_object_sync_job'
require 'salesforce_ar_sync/jobs/delete_object_job'
require 'salesforce_ar_sync/jobs/sync_object_job'

module SalesforceArSync
  mattr_accessor :app_root
  mattr_accessor :config

  def self.setup
    yield self
  end
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend SalesforceArSync::Extenders::SalesforceSyncable
end
