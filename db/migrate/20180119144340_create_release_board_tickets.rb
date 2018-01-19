class CreateReleaseBoardTickets < ActiveRecord::Migration[5.1]
  def change
    create_table :release_board_tickets do |t|
      t.references :release
      t.references :board_ticket

      t.timestamps
    end
  end
end
