# frozen_string_literal: true

module SalesforceArSync
  class SyncObjectJob < ::ApplicationJob
    queue_as SalesforceArSync.config['SYNC_QUEUE']

    def perform(klass, sobject)
      klass = klass.camelize.constantize if klass.is_a?(String)
      klass.salesforce_update(sobject)
    end
  end
end
