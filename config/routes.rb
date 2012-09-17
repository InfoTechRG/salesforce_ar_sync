SalesforceArSync::Engine.routes.draw do
  match '/sf_soap/delete' => 'salesforce_ar_sync::soap_message#delete', :via => :post
  match '/sf_soap/*klass' => 'salesforce_ar_sync::soap_message#sync_object', :via => :post
end