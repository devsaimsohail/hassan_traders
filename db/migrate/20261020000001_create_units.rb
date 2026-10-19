class CreateUnits < ActiveRecord::Migration[8.1]
  DEFAULTS = %w[pcs dozen gross kg gram meter gaz than cone roll suit set bag carton litre].freeze

  def up
    create_table :units do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :units, "company_id, lower(name)", unique: true, name: "index_units_on_company_id_and_lower_name"

    # Every company gets the units its items already use (first spelling wins), then the basic ones.
    execute <<~SQL.squish
      INSERT INTO units (company_id, name, created_at, updated_at)
      SELECT DISTINCT ON (company_id, lower(unit)) company_id, unit, now(), now()
      FROM items WHERE trim(unit) <> '' ORDER BY company_id, lower(unit), id
    SQL
    execute <<~SQL.squish
      INSERT INTO units (company_id, name, created_at, updated_at)
      SELECT companies.id, defaults.name, now(), now()
      FROM companies CROSS JOIN unnest(ARRAY[#{DEFAULTS.map { |n| connection.quote(n) }.join(", ")}]) AS defaults(name)
      ON CONFLICT DO NOTHING
    SQL
    execute <<~SQL.squish
      UPDATE items SET unit = units.name FROM units
      WHERE units.company_id = items.company_id AND lower(units.name) = lower(items.unit) AND units.name <> items.unit
    SQL
  end

  def down
    drop_table :units
  end
end
