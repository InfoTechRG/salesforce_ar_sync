# frozen_string_literal: true

module SalesforceArSync
  class DeleteObjectJob < (defined?(::ApplicationJob) ? ::ApplicationJob : ActiveJob::Base)
    queue_as SalesforceArSync.config['JOB_QUEUE']

    def perform(klass, sobject)
      klass = klass.safe_constantize if klass.is_a?(String)
      klass.delete_object(sobject)
    end
  end
end
