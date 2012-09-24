require 'ipaddr'

module SalesforceArSync
  class IPConstraint
    def initialize
    	@ip_ranges = SalesforceArSync.config["IP_RANGES"]
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