class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :recipient, foreign_key: { to_table: :users }, type: :uuid
      t.bigint :amount_cents, null: false, default: 0
      t.integer :kind, null: false
      t.string :idempotency_key, null: false

      t.timestamps
    end

    add_index :transactions, :idempotency_key, unique: true
  end
end
