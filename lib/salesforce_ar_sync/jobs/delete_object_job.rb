# frozen_string_literal: true

module SalesforceArSync
  class DeleteObjectJob < BaseJob
    def perform(klass, sobject)
      prepare_class(klass).delete_object(sobject)
    end
  end
end
