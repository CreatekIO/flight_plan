class AddRememberCreatedAtToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :remember_created_at, :datetime
  end
end
