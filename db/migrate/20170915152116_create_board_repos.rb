class CreateBoardRepos < ActiveRecord::Migration[5.1]
  def change
    create_table :board_repos do |t|
      t.references :board
      t.references :repo

      t.timestamps
    end
  end
end
