module SalesforceArSync
  class Railtie < Rails::Railtie
    initializer 'salesforce_ar_sync.insert_middleware' do |app|
      if ::Rails.version < "5.0"
        puts "USING PARAMS PARSER"
        config.app_middleware.insert_after ActionDispatch::ParamsParser, ActionDispatch::XmlParamsParser
      else
        ActionPack::XmlParser.register
        # config.app_middleware.insert_after ActionDispatch::Flash, ActionDispatch::XmlParamsParser
      end
    end
  end
end
