class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.bigint :balance_cents, null: false, default: 0

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_check_constraint :users, "balance_cents >= 0", name: "users_balance_cents_non_negative"
  end
end
