class CreateItemsAndStockMoves < ActiveRecord::Migration[8.1]
  def up
    create_table :items do |t|
      t.references :company, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.string :unit, null: false
      t.integer :rate, null: false, default: 0
      t.integer :sale_price
      t.decimal :reorder_level, precision: 12, scale: 3, null: false, default: 0
      t.decimal :opening_qty, precision: 12, scale: 3, null: false, default: 0
      t.timestamps
    end
    add_index :items, [ :company_id, :code ], unique: true
    add_index :items, [ :company_id, :name ], unique: true
    add_check_constraint :items, "category IN ('raw_material', 'product')", name: "items_category"

    create_table :stock_moves do |t|
      t.references :company, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.date :date, null: false
      t.string :direction, null: false
      t.string :reason, null: false
      t.decimal :qty, precision: 12, scale: 3, null: false
      t.string :ref
      t.string :note
      t.datetime :created_at, null: false
    end
    add_index :stock_moves, [ :company_id, :date ]
    add_index :stock_moves, [ :item_id, :date ]
    add_index :stock_moves, [ :company_id, :ref ]
    add_check_constraint :stock_moves, "qty > 0", name: "stock_moves_qty_positive"
    add_check_constraint :stock_moves, "direction IN ('in', 'out')", name: "stock_moves_direction"

    execute <<~SQL
      CREATE FUNCTION append_only_row() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION '% is append-only', TG_TABLE_NAME;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER stock_moves_append_only
        BEFORE UPDATE OR DELETE ON stock_moves
        FOR EACH ROW EXECUTE FUNCTION append_only_row();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS stock_moves_append_only ON stock_moves"
    execute "DROP FUNCTION IF EXISTS append_only_row()"
    drop_table :stock_moves
    drop_table :items
  end
end
