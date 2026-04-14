class AddBalanceCheckConstraintToUsers < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :users, "balance >= 0", name: "users_balance_non_negative"
  end
end
