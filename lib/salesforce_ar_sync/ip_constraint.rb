require 'ipaddr'

module SalesforceArSync
  class IPConstraint
    def initialize
    	@ip_ranges = SALESFORCE_AR_SYNC_CONFIG["IP_RANGES"]
    end
 
    def matches?(request)
    	if Rails.env == 'development' || Rails.env == 'test'
  	  	true
    	else
    		@ip_ranges.any?{|r| IPAddr.new(r).include?(IPAddr.new(request.remote_ip)) }
    	end
    end
  end
end