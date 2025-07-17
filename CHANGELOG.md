# Version 1.1.0
* Salesforce objects you wish to sync no longer need to be materialized
* Requires that `SF_CLIENT` be initialized in your databasedotcom configuration

# Version 1.1.1
* Adds missed paths to the gemspec to fix initialization issues when used as a gem

# Version 1.1.2
* Adds support for namespaced Salesforce apps

# Version 1.1.3
* Adds support for outbound deletions
* Adds ability to configure inbound/outbound deletions on a per model basis

# Version 1.1.4
* Fix issue with multi-select picklists introduced when using REST API

# Version 2.0.0
* Add active record web id field
* Moved from Rails 3 to Rails 4

# Version 2.0.1
* Add the ability to map delete messages to any model without modifying the outbound message in Salesforce

# Version 2.0.2
* Updated IP address ranges for Salesforce.

# Version 3.2.0
* Adds support for Rails 5
* Added ability to specify readonly fields for salesforce syncable models so those fields don't try to sync back to Salesforce
* WebID syncing fixed

# Version 4.0.0
* Changed Databasedotcom over to Restforce

# Version 4.1.0
* Add rexml dependency to support Ruby 3.0

# Version 5.0.0
* Replace .delay calls with ActiveJobs
* Add job_queue config

# Version 5.1.0
* Updated Psych Processing

# Version 5.2.0
* Added the ability to manually trigger syncing of specific model attributes.

# Version 5.2.1
* Reverted accidental change to object creation during sync.
