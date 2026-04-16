class AddNotNullToTransactionsIdempotencyKey < ActiveRecord::Migration[8.1]
  def change
    change_column_null :transactions, :idempotency_key, false
  end
end
