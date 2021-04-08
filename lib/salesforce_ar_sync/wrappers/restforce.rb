# We'll expose a public interface that only contains the methods we need here
module SalesforceArSync
  module Wrappers
    class Restforce
      attr_accessor :sf_client
      def initialize(sf_client)
        @sf_client = sf_client
      end

      # def find(sobject, id, field = nil)
      #   @sf_client.find(sobject, id, field)
      # end

      def http_post; end

      def http_patch; end

      def http_delete; end
    end
  end
end
