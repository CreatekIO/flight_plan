class AddCreatorColumnsToTicket < ActiveRecord::Migration[5.1]
  def change
    add_column :tickets, :creator_remote_id, :integer
    add_column :tickets, :creator_username, :string

    add_index :tickets, :creator_remote_id
    add_index :tickets, :creator_username
  end
end
