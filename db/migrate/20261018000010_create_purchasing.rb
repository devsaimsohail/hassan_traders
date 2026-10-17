class CreatePurchasing < ActiveRecord::Migration[8.1]
  def up
    create_table :suppliers do |t|
      t.references :company, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :city
      t.string :phone
      t.string :supplies
      t.timestamps
    end
    add_index :suppliers, [ :company_id, :code ], unique: true
    add_index :suppliers, [ :company_id, :name ], unique: true

    change_table :items, bulk: true do |t|
      t.change :rate, :decimal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :last_purchase_rate, precision: 12, scale: 2
      t.date :last_purchase_on
      t.references :default_supplier, foreign_key: { to_table: :suppliers }
    end

    create_table :purchase_orders do |t|
      t.references :company, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.string :number, null: false
      t.date :date, null: false
      t.string :status, null: false, default: "draft"
      t.integer :total, null: false, default: 0
      t.string :note
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.references :received_by, foreign_key: { to_table: :users }
      t.date :received_on
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.datetime :cancelled_at
      t.string :cancel_reason
      t.timestamps
    end
    add_index :purchase_orders, [ :company_id, :number ], unique: true
    add_index :purchase_orders, [ :company_id, :date ]
    add_check_constraint :purchase_orders, "status IN ('draft', 'pending_approval', 'approved', 'received', 'cancelled')", name: "purchase_orders_status"

    create_table :purchase_order_lines do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.decimal :qty, precision: 12, scale: 3, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false
      t.integer :amount, null: false
      t.timestamps
    end
    add_check_constraint :purchase_order_lines, "qty > 0", name: "purchase_order_lines_qty_positive"
    add_check_constraint :purchase_order_lines, "rate >= 0", name: "purchase_order_lines_rate"

    create_table :supplier_payments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :purchase_order, foreign_key: true
      t.date :date, null: false
      t.integer :amount, null: false
      t.string :method, null: false
      t.string :ref
      t.references :user, null: false, foreign_key: true
      t.datetime :created_at, null: false
    end
    add_check_constraint :supplier_payments, "amount > 0", name: "supplier_payments_amount_positive"

    execute <<~SQL
      CREATE TRIGGER supplier_payments_append_only
        BEFORE UPDATE OR DELETE ON supplier_payments
        FOR EACH ROW EXECUTE FUNCTION append_only_row();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS supplier_payments_append_only ON supplier_payments"
    drop_table :supplier_payments
    drop_table :purchase_order_lines
    drop_table :purchase_orders
    change_table :items, bulk: true do |t|
      t.remove_references :default_supplier
      t.remove :last_purchase_on, :last_purchase_rate
      t.change :rate, :integer, null: false, default: 0
    end
    drop_table :suppliers
  end
end
