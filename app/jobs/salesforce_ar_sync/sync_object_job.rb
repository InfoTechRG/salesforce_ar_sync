# frozen_string_literal: true

module SalesforceArSync
  class SyncObjectJob < (defined?(::ApplicationJob) ? ::ApplicationJob : ActiveJob::Base)
    queue_as SalesforceArSync.config['JOB_QUEUE']

    def perform(klass, sobject)
      klass = klass.camelize.constantize if klass.is_a?(String)
      klass.salesforce_update(sobject)
    end
  end
end
