# frozen_string_literal: true

module SalesforceArSync
  class SyncObjectJob < BaseJob
    def perform(klass, sobject)
      prepare_class(klass).salesforce_update(sobject)
    end
  end
end
