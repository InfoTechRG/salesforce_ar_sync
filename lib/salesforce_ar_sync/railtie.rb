module SalesforceArSync
  class Railtie < Rails::Railtie
    initializer 'salesforce_ar_sync.insert_middleware' do |app|
      app.config.middleware.insert_after ActionDispatch::ParamsParser, ActionPack::XmlParser
    end
  end
end
