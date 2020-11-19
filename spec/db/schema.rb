ActiveRecord::Schema.define(:version => 1) do
  create_table "contacts", :force => true do |t|
    t.string :first_name
    t.string :last_name
    t.string :phone
    t.string :email
    t.integer :number_of_posts
    t.string :salesforce_id
    t.datetime :salesforce_updated_at
    t.string :sync_inbound_delete
    t.string :sync_outbound_delete
    t.timestamps
  end

  create_table 'vendors', force: true do |t|
    t.string :name
    t.string :salesforce_id
    t.datetime :salesforce_updated_at
    t.string :sync_inbound_delete
    t.string :sync_outbound_delete
    t.timestamps null: false
  end

  create_table "users", :force => true do |t|
    t.timestamps
  end

  create_table "delete_tests", :force => true do |t|
    t.timestamps
  end

  create_table "sync_tests", :force => true do |t|
    t.timestamps
  end

  create_table "process_update_tests", :force => true do |t|
    t.timestamps
    t.datetime :salesforce_updated_at
    t.string :salesforce_id
  end
end
