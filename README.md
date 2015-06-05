# SalesforceArSync

SalesforceARSync allows you to sync models and fields with Salesforce through a combination of
Outbound Messaging, SOAP and databasedotcom.

## Installation

### Requirements

* Rails >= 4.0
* Salesforce.com instance
* [Have your 18 character organization id ready](#finding-your-18-character-organization-id)
* databasedotcom gem >= 1.3 installed and configured [see below](#databasedotcom)
* delayed_job gem >= 3.0 installed and configured
* actionpack-xml_parser gem installed(if using Rails >= 4.0) [see below](#actionpack-xml_parser)

### Salesforce Setup

Before you can start syncing your data several things must be completed in Salesforce.

#### 1. Setup Remote Access
Create a new Remote Access Application entry by going to

    Setup -> Develop -> Remote Access

You can use http://localhost/nothing for the _Callback URL_

#### 2. Setup Outbound Messaging
Each model you wish to sync requires a workflow to trigger outbound messaging. You can set the worflow
to trigger on the specific fields you wish to update.

    Setup -> Create -> Workflow & Approvals -> Worflow Rules

Click _New Rule_, select the object (model) you wish to sync and click _Next_, give the rule a name, select
_Every time a record is created or edited_ and set a rule on the field(s) you want to sync ( a formula checking
if the fields have changed is recommended). Click _Save & Next_, in the _Add Worflow Action_ dropdown select
_New Outbound Message_. Enter a name and set the _Endpoint URL_ to be http://yoursite.com/integration/sf_soap/model_name.
Select the fields you wish to sync (Id and SystemModstamp are required).

*You need to do this for each object/model you want to sync.

### databasedotcom

Before using the salesforce_ar_sync gem you must ensure you have the databasedotcom gem installed and configured
properly. Make sure each of the models you wish to sync are materialized.

````ruby
$sf_client = Databasedotcom::Client.new("config/databasedotcom.yml")
$sf_client.authenticate :username => <username>, :password => <password>

module SalesforceArSync::SalesforceSync
  SF_CLIENT = $sf_client
end
````

### actionpack-xml_parser
Rails 4.0 removed support for parsing XML parameters form the request. However, the salesforce_ar_sync gem depends on this for handling Outbound Messages from Salesforce. If you are using salesforce_ar_sync with Rails >= 4.0, you will need to add the [actionpack-xml_parser](https://github.com/rails/actionpack-xml_parser) gem to your Gemfile:

`gem 'actionpack-xml_parser'`

You then need to add the following line to `config/application.rb`:
````ruby
config.middleware.insert_after ActionDispatch::ParamsParser, ActionDispatch::XmlParamsParser
````

### Gem Installation

Add this line to your application's Gemfile:

    gem 'salesforce_ar_sync'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install salesforce_ar_sync

### Application Setup

Before using the gem you must complete the setup of your rails app.

The gem needs to know your 18 character organization id, it can be stored in a YAML file or in the ENV class.

To create the yaml file run

    $ rails generate salesforce_ar_sync:configuration <organization id>

Next you will need to decide which models you want to sync. For each model you must create a migration and run them

    $ rails generate salesforce_ar_sync:migrations <models> --migrate

To mount the engine add the following line to your routes.rb file

	mount SalesforceArSync::Engine => '/integration'

You can change '/integration' to whatever you want, all of the engine routes will be based off of this path. Running

	$ rake routes | grep salesforce_ar_sync

will show you all of the gems routes, make sure you point your outbound messages at these urls.

Next you will need to tell the gem which models are syncable by adding _salesforce_syncable_ to your model class
and specifying which attributes you would like to sync.

````ruby
salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name}
````

The first parameter in the _:sync_attributes_ hash is the Salesforce field name and the second is the model attribute
name.

## Usage

### Configuration Options

The gem can be configured using a YAML file or with the ENV variable.

The options available to configure are

* __organization_id__: the 18 character organization id of your Salesforce instance
* __sync_enabled__: a global sync enabled flag which is a boolean true/false
* __namespace_prefix__: Namespace prefix of your Salesforce app in case you specified one

To generate a YAML file

    $ rails generate salesforce_ar_sync:configuration

Or with an organization id

    $ rails generate salesforce_ar_sync:configuration 123456789123456789

which will create a template salesforce_ar_sync.yml in /config that looks like the following

    organization_id: <organization id> #18 character organization_id
    sync_enabled: true
    namespace_prefix:


To use the ENV variable you must pass environemnt variables to rails via the _export_ command in bash or before the
initializer loads the ENV settings.

    $ export SALESFORCE_AR_SYNC_ORGANIZATION_ID=123456789123456789
    $ export SALESFORCE_AR_SYNC_SYNC_ENABLED=true
    $ export SALESFORCE_AR_NAMESPACE_PREFIX=my_prefix

### Model Options
The model can have several options set:

[__salesforce_sync_enabled__](#salesforce_sync_enabled)
[__sync_attributes__](#sync_attributes)
[__async_attributes__](#async_attributes)
[__default_attributes_for_create__](#default_attributes_for_create)
[__salesforce_id_attribute_name__](#salesforce_id_attribute_name)
[__web_id_attribute_name__](#web_id_attribute_name)
[__activerecord_web_id_attribute_name__](#activerecord_web_id_attribute_name)
[__salesforce_sync_web_id__](#salesforce_sync_web_id)
[__web_class_name__](#web_class_name)
[__salesforce_object_name__](#salesforce_object_name)
[__except__](#except)

#### <a id="salesforce_sync_enabled"></a>salesforce_sync_enabled
Model level option to enable disable the sync, defaults to true.

````ruby
:salesforce_sync_enabled => false
````

#### sync_attributes
Hash mapping of Salesforce attributes to web attributes, defaults to empty hash.
"Web" attributes can be actual method names to return a custom value.If you are providing a method name to return a
value, you should also implement a corresponding my_method_changed? to return if the value has changed.  Otherwise
it will always be synced.

````ruby
:sync_attributes => { :Email => :login, :FirstName => :first_name, :LastName => :last_name }
````

#### async_attributes
An array of Salesforce attributes which should be synced asynchronously, defaults to an empty array. When an object is saved and only attributes contained in this array, the save to Salesforce will be queued and processed asyncronously.
Use this carefully, nothing is done to ensure data integrity, if multiple jobs are queued for a single object there is no way to guarentee that they are processed in order, or that the save to Salesforce will succeed.

````ruby
:async_attributes => ["Last_Login__c", "Login_Count__c"]
````

Note:  The model will fall back to synchronous sync if non-synchronous attributes are changed along with async
attributes

#### default_attributes_for_create
A hash of default attributes that should be used when we are creating a new record, defaults to empty hash.

````ruby
:default_attributes_for_create => {:password_change_required => true}
````

#### salesforce_id_attribute_name
The "Id" attribute of the corresponding Salesforce object, defaults to _Id_.

````ruby
:salesforce_id_attribute_name => :Id
````

#### web_id_attribute_name
The field name of the web id attribute in the Salesforce Object, defaults to _WebId__c_

````ruby
:web_id_attribute_name  => :WebId__c
````

#### activerecord_web_id_attribute_name
The field name of the web id attribute in the ActiveRecord Object, defaults to id

````ruby
:activerecord_web_id_attribute_name  => :id
````

#### salesforce_sync_web_id
Enable or disable sync of the web id, defaults to false. Use this if you have a need for the id field of the ActiveRecord model to by synced to Salesforce.

````ruby
:salesforce_sync_web_id => false
````

#### web_class_name
The name of the Web Objects class. A custom value can be provided if you wish to sync to a SF object and back to a
different web object. Defaults to the model name. This would generally be used if you wanted to flatten a web object
into a larger SF object like Contact.

````ruby
:web_class_name => 'Contact',
````

#### salesforce_object_name
Optionally holds the name of a method which will return the name of the Salesforce object to sync to, defaults to nil.

````ruby
:salesforce_object_name => :salesforce_object_name_method_name
````

#### except
Optionally holds the name of a method which can contain logic to determine if a record should be synced on save. If no
method is given then only the salesforce_skip_sync attribute is used. Defaults to nil.

````ruby
:except => :except_method_name
````

### Stopping the Sync

Stopping the gem from syncing can be done on three levels.

* The global level before the app starts via the .yml file, ENV variables or after the app starts with the gem's
configuration variable _SALESFORCE_AR_SYNC_CONFIG["SYNC_ENABLED"]_
* The model level by setting the _:salesforce_sync_enabled => false_ or _:except => :method_name_
* The instance level by setting _:salesforce_skip_sync => true_ in the instance

## Examples

### Our Basic Example Model

```ruby
class Contact < ActiveRecord::Base
  attributes :first_name, :last_name, :phone, :email, :last_login_time, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name, :phone, :email, :last_login_time
end
```

### Making the Model Syncable

```ruby
class Contact < ActiveRecord::Base
  attributes :first_name, :last_name, :phone, :email, :last_login_time, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name, :phone, :email

  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone, :Email => :email}
end
```

### Stopping the Model from Syncing with a Flag

```ruby
class Contact < ActiveRecord::Base
  attributes :first_name, :last_name, :phone, :email, :last_login_time, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name, :phone, :email

  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone, :Email => :email},
                      :salesforce_sync_enabled => false
end
```

### Stopping the Model from Syncing with a Method

```ruby
class Contact < ActiveRecord::Base
  attributes :first_name, :last_name, :phone, :email, :last_login_time, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name, :phone, :email

  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone, :Email => :email},
                      :except => :skip_sync?

  def skip_sync?
    if first_name.blank?
      return true
    end
  end
end
```

### Stopping a Record from Syncing

```ruby
customer = Contact.find_by_email('test@example.com')
customer.salesforce_skip_sync = true
```

### Specify Async Attributes

```ruby
class Contact < ActiveRecord::Base
  attributes :first_name, :last_name, :phone, :email, :last_login_time, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name, :phone, :email, :last_login_time

  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone, :Email => :email, :Last_Login_Time__c => :last_login_time},
                      :async_attributes => ["Last_Login_Time__c"]
end
```

### Specify Default Attributes when an Object is Created

```ruby
class Contact < ActiveRecord::Base
  attributes :first_name, :last_name, :phone, :email, :last_login_time, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name, :phone, :email, :last_login_time

  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone, :Email => :email},
                      :default_attributes_for_create => {:password_change_required => true}
end
```

### Relationships
If you want to keep the standard ActiveRecord associations in place, but need to populate these relationships from Salesforce records, you can define
methods in your models to add to the attribute mapping.

The following example shows a Contact model, which is related to an Account model through account_id, we implement a getter, setter and _changed? method
to do our lookups and map these methods in our sync_attributes mapping instead of the standard attributes. This allows us to send/receive messages from Salesforce
using the 18 digit Salesforce id, but maintain our ActiveRecord relationships.

```ruby

	class Contact < ActiveRecord::Base
		attributes :first_name, :last_name, :account_id
		attr_accessor :first_name, :last_name, :account_id

		salesforce_syncable :sync_attributes => { :FirstName => :first_name,
																							:LastName => :last_name,
																							:AccountId => :salesforce_account_id }

		def salesforce_account_id_changed?
		  account_id_changed?
		end

		def salesforce_account_id
		  return nil if account_id.nil?
		  account.salesforce_id
		end

		def salesforce_account_id=(account_id)
		  self.account = nil if account_id.nil? and return
		  self.account = Account.find_or_create_by_salesforce_id(account_id)
		end
	end

```

### Defining a Custom Salesforce Object

```ruby
class Contact < ActiveRecord::Base
  attributes :first_name, :last_name, :phone, :email, :last_login_time, :salesforce_id, :salesforce_updated_at
  attr_accessor :first_name, :last_name, :phone, :email, :last_login_time

  salesforce_syncable :sync_attributes => {:FirstName => :first_name, :LastName => :last_name, :Phone => :phone, :Email => :email},
                      :salesforce_object_name => :custom_salesforce_object_name

  def custom_salesforce_object_name
    "CustomContact__c"
  end
end
```

## Deletes
### Inbound Deletes
In order to handle the delete of objects coming from Salesforce, a bit of code is necessary because an Outbound Message cannot be triggered when
an object is deleted. To work around this you will need to create a new Custom Object in your Salesforce environment:

```
	Deleted_Object__C
		Object_Id__c_ => Text(18)
		Object_Type__c_ => Text(255)
```

Object_Id__c will hold the 18 digit Id of the record being deleted.
Object_Type__c will hold the name of the Rails Model that the Salesforce object is synced with.

If you trigger a record to be written to this object whenever another object is deleted, and configure an Outbound Message to send to the /sf_soap/delete action
whenever a Deleted_Object__c record is created, the corresponding record will be removed from your Rails app.

Syncing inbound deletes is enabled by default, but can be configured in the Rails Model.
This is done using the :sync_inbound_delete option, which can take either a boolean value, or the name of a method that returns a boolean value.

```ruby
  salesforce_syncable :sync_inbound_delete => :inbound_delete
                     #:sync_inbound_delete => true
  def inbound_delete
    return self.comments.count == 0
  end
```

### Outbound Deletes
Syncing outbound deletes to Salesforce is disabled by default, but can be configured in the Rails Model.
This is done using the :sync_outbound_delete option, which can take either a boolean value, or the name of a method that returns a boolean value.

```ruby
  salesforce_syncable :sync_outbound_delete => :outbound_delete
                     #:sync_outbound_delete => false

  def outbound_delete
    return self.is_trial_user?
  end
```

## Errors

### Outbound Message Errors

If the SOAP handler encounters an error it will be recorded in the log of the outbound message in Salesforce. To view the message go to

    Setup -> Monitoring -> Outbound Messages

## <a id="orga_id"></a>Finding your 18 Character Organization ID
 Your 15 character organization id can be found in _Setup -> Company Profile -> Company Information_. You must convert
 it to an 18 character id by running it through the tool located here:
 http://cloudjedi.wordpress.com/no-fuss-salesforce-id-converter/ or by installing the Force.com Utility Belt for Chrome.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
