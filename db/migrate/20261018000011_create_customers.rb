class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :company, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :city
      t.string :area
      t.string :phone
      t.integer :credit_limit, null: false, default: 0
      t.integer :terms_days, null: false, default: 30
      t.integer :opening_balance, null: false, default: 0
      t.string :note
      t.timestamps
    end
    add_index :customers, [ :company_id, :code ], unique: true
    add_index :customers, [ :company_id, :name ], unique: true
    add_check_constraint :customers, "credit_limit >= 0 AND terms_days >= 0", name: "customers_limits"
  end
end
