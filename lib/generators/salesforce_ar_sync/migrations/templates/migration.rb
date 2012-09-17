class AddSalesforceFieldsTo<%= @model_name.pluralize %> < ActiveRecord::Migration
  def up
    add_column :<%= @table_name %>, :salesforce_id, :string, :limit => 18
    add_column :<%= @table_name %>, :salesforce_updated_at, :datetime

    add_index :<%= @table_name %>, :salesforce_id, :unique => true
  end
  
  def down
    remove_column :<%= @table_name %>, :salesforce_id
    remove_column :<%= @table_name %>, :salesforce_updated_at
  end
end
