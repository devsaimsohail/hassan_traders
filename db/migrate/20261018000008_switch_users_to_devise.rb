class SwitchUsersToDevise < ActiveRecord::Migration[8.1]
  def change
    drop_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    change_table :users, bulk: true do |t|
      t.rename :password_digest, :encrypted_password
      t.rename :failed_login_count, :failed_attempts
      t.rename :locked_until, :locked_at
      t.rename :last_login_at, :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :remember_created_at
    end
  end
end
