# frozen_string_literal: true

module SalesforceArSync
  class DeleteObjectJob < BaseJob
    def perform(klass, sobject)
      klass = prepare_class(klass)
      klass.delete_object(sobject)
    end
  end
end
