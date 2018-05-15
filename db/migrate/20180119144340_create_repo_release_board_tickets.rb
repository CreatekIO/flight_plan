class CreateRepoReleaseBoardTickets < ActiveRecord::Migration[5.1]
  def change
    create_table :repo_release_board_tickets do |t|
      t.references :repo_release
      t.references :board_ticket

      t.timestamps
    end
  end
end
