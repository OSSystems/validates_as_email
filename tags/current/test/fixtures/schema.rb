ActiveRecord::Schema.define do
  create_table :emails, :force => true do |t|
    t.column :id, :string, :null => true
    t.column :mail, :string, :null => false
  end
end
