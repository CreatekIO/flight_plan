class AddSwimlaneSequenceToBoardTicket < ActiveRecord::Migration[5.1]
  def change
    add_column :board_tickets, :swimlane_sequence, :integer
    add_index :board_tickets, [:swimlane_id, :swimlane_sequence], unique: true
  end
end
