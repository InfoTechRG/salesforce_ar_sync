# frozen_string_literal: true

module SalesforceArSync
  class DeleteObjectJob < ::ApplicationJob
    queue_as SalesforceArSync.config['SYNC_QUEUE']

    def perform(klass, sobject)
      klass = klass.safe_constantize if klass.is_a?(String)
      klass.delete_object(sobject)
    end
  end
end
