class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :mobile, null: false, index: { unique: true }
      t.string :email
      t.string :city
      t.string :password_digest, null: false
      t.boolean :must_change_password, null: false, default: false
      t.integer :failed_login_count, null: false, default: 0
      t.datetime :locked_until
      t.datetime :last_login_at
      t.string :last_device
      t.datetime :disabled_at
      t.references :disabled_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
