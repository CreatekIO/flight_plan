class AddUsernameToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :username, :string, after: :uid
    add_index :users, :username
  end
end
