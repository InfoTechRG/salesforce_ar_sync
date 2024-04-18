# frozen_string_literal: true

module SalesforceArSync
  class SyncObjectJob < BaseJob
    def perform(klass, sobject)
      klass = prepare_class(klass)
      klass.salesforce_update(sobject)
    end
  end
end
