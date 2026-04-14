class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.decimal :balance, precision: 15, scale: 2, null: false, default: 0

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
