class AddMergedToTicket < ActiveRecord::Migration[5.1]
  def change
    add_column :tickets, :merged, :boolean, default: false
  end
end
