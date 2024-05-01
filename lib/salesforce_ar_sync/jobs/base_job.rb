# frozen_string_literal: true

module SalesforceArSync
  class BaseJob < (defined?(::ApplicationJob) ? ::ApplicationJob : ActiveJob::Base)
    queue_as do
      SalesforceArSync.config['JOB_QUEUE']
    end

    protected

    def prepare_class(klass)
      klass.is_a?(String) ? klass.camelize.constantize : klass
    end
  end
end
