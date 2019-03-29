class AddMilestoneIdToTickets < ActiveRecord::Migration[5.1]
  def change
    add_reference :tickets, :milestone, foreign_key: true
  end
end
