module SalesforceArSync
  class SoapMessageController < ::ApplicationController

    protect_from_forgery with: :null_session
    before_filter :validate_ip_ranges

    def sync_object
      delayed_soap_handler SalesforceArSync::SoapHandler::Base
    end

    def delete
      delayed_soap_handler SalesforceArSync::SoapHandler::Delete
    end

    private

    def delayed_soap_handler(klass)
      priority = SalesforceArSync.config['DELAYED_TASKS_PRIORITY'] || 90
      begin
        soap_handler = klass.new(SalesforceArSync.config["ORGANIZATION_ID"], params)
        soap_handler.process_notifications(priority) if soap_handler.sobjects
        render :xml => soap_handler.generate_response, :status => :created
      rescue Exception => ex
        render :xml => soap_handler.generate_response(ex), :status => :created
      end
    end

    # to be used in a before_filter, checks ip ranges specified in configuration
    # and renders a 404 unless the request matches
    def validate_ip_ranges
      raise ActionController::RoutingError.new('Not Found') unless SalesforceArSync::IPConstraint.new.matches?(request)
    end
  end
end