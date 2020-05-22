class AddRemoteClosedAtToTicket < ActiveRecord::Migration[5.1]
  def change
    add_column :tickets, :remote_closed_at, :datetime
  end
end
