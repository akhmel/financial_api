class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :recipient, foreign_key: { to_table: :users }, type: :uuid
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.integer :kind, null: false

      t.timestamps
    end
  end
end
