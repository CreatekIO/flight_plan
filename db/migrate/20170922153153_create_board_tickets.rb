class CreateBoardTickets < ActiveRecord::Migration[5.1]
  def change
    create_table :board_tickets do |t|
      t.references :board
      t.references :ticket
      t.references :swimlane

      t.timestamps
    end
  end
end
