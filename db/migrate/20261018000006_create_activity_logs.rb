class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def up
    create_table :activity_logs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :user_name
      t.string :role
      t.string :action, null: false
      t.string :section, null: false
      t.string :ref
      t.string :detail, null: false
      t.jsonb :old_value
      t.jsonb :new_value
      t.string :device
      t.string :ip
      t.datetime :created_at, null: false
    end
    add_index :activity_logs, [ :company_id, :created_at ]

    execute <<~SQL
      CREATE FUNCTION activity_logs_append_only() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'activity_logs is append-only';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER activity_logs_append_only
        BEFORE UPDATE OR DELETE ON activity_logs
        FOR EACH ROW EXECUTE FUNCTION activity_logs_append_only();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS activity_logs_append_only ON activity_logs"
    execute "DROP FUNCTION IF EXISTS activity_logs_append_only()"
    drop_table :activity_logs
  end
end
