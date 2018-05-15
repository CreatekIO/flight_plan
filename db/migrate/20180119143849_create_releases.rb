class CreateReleases < ActiveRecord::Migration[5.1]
  def change
    create_table :releases do |t|
      t.references :board
      t.string :title
      t.string :branch_name

      t.timestamps
    end
  end
end
