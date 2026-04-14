class AddPasswordDigestToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_digest, :string, null: false, default: ""
    change_column_default :users, :password_digest, nil
  end
end
