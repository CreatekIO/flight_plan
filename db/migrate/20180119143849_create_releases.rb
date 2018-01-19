class CreateReleases < ActiveRecord::Migration[5.1]
  def change
    create_table :releases do |t|
      t.references :board
      t.references :repo
      t.string :title
      t.string :source_branch
      t.string :target_branch
      t.string :remote_title
      t.integer :remote_id
      t.integer :remote_number
      t.string :remote_url
      t.string :remote_state
      t.datetime :remote_merged_at

      t.timestamps
    end
  end
end
