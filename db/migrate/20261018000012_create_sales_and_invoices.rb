class CreateSalesAndInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_orders do |t|
      t.references :company, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :number, null: false
      t.date :date, null: false
      t.string :status, null: false, default: "pending"
      t.integer :amount, null: false, default: 0
      t.string :note
      t.references :booked_by, null: false, foreign_key: { to_table: :users }
      t.date :dispatched_on
      t.references :dispatched_by, foreign_key: { to_table: :users }
      t.date :delivered_on
      t.references :delivered_by, foreign_key: { to_table: :users }
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.datetime :cancelled_at
      t.string :cancel_reason
      t.timestamps
    end
    add_index :sales_orders, [ :company_id, :number ], unique: true
    add_index :sales_orders, [ :company_id, :date ]
    add_check_constraint :sales_orders, "status IN ('pending', 'dispatched', 'delivered', 'cancelled')", name: "sales_orders_status"

    create_table :sales_order_lines do |t|
      t.references :sales_order, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.decimal :qty, precision: 12, scale: 3, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false
      t.integer :amount, null: false
      t.timestamps
    end
    add_check_constraint :sales_order_lines, "qty > 0 AND rate >= 0", name: "sales_order_lines_values"

    create_table :invoices do |t|
      t.references :company, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :sales_order, foreign_key: true, index: { unique: true }
      t.string :number, null: false
      t.date :date, null: false
      t.date :due_date, null: false
      t.integer :amount, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.datetime :cancelled_at
      t.string :cancel_reason
      t.timestamps
    end
    add_index :invoices, [ :company_id, :number ], unique: true
    add_index :invoices, [ :company_id, :date ]
    add_index :invoices, [ :customer_id, :due_date ]

    create_table :invoice_lines do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.decimal :qty, precision: 12, scale: 3, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false
      t.integer :amount, null: false
      t.timestamps
    end
  end
end
