class CreatePayments < ActiveRecord::Migration[8.1]
  def up
    create_table :payments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :invoice, foreign_key: true
      t.string :number, null: false
      t.string :against, null: false
      t.date :date, null: false
      t.string :method, null: false
      t.string :ref
      t.integer :amount, null: false
      t.references :received_by, null: false, foreign_key: { to_table: :users }
      t.datetime :reversed_at
      t.references :reversed_by, foreign_key: { to_table: :users }
      t.string :reverse_reason
      t.datetime :created_at, null: false
    end
    add_index :payments, [ :company_id, :number ], unique: true
    add_index :payments, [ :company_id, :date ]
    add_index :payments, [ :customer_id, :date ]
    add_check_constraint :payments, "amount > 0", name: "payments_amount_positive"
    add_check_constraint :payments, "against IN ('bill', 'opening_balance', 'on_account')", name: "payments_against"
    add_check_constraint :payments, "(against = 'bill') = (invoice_id IS NOT NULL)", name: "payments_bill_has_invoice"

    execute <<~SQL
      CREATE FUNCTION payments_only_reverse() RETURNS trigger AS $$
      BEGIN
        IF TG_OP = 'DELETE' THEN
          RAISE EXCEPTION 'payments can not be deleted';
        END IF;
        IF OLD.reversed_at IS NOT NULL OR
           (to_jsonb(NEW) - 'reversed_at' - 'reversed_by_id' - 'reverse_reason') <> (to_jsonb(OLD) - 'reversed_at' - 'reversed_by_id' - 'reverse_reason') THEN
          RAISE EXCEPTION 'payments can only be reversed, once';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER payments_only_reverse
        BEFORE UPDATE OR DELETE ON payments
        FOR EACH ROW EXECUTE FUNCTION payments_only_reverse();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS payments_only_reverse ON payments"
    execute "DROP FUNCTION IF EXISTS payments_only_reverse()"
    drop_table :payments
  end
end
