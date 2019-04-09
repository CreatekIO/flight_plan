class AddRemoteTimestampsToTicketsAndComments < ActiveRecord::Migration[5.1]
  def change
    add_column :tickets, :remote_created_at, :datetime
    add_column :tickets, :remote_updated_at, :datetime

    add_column :comments, :remote_created_at, :datetime
    add_column :comments, :remote_updated_at, :datetime
  end
end
