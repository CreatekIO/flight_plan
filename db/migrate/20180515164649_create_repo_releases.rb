class CreateRepoReleases < ActiveRecord::Migration[5.1]
  def change
    create_table :repo_releases do |t|
      t.references :repo, foreign_key: true
      t.references :release, foreign_key: true
      t.string :status
      t.integer :remote_id
      t.integer :remote_number
      t.string :remote_url
      t.string :remote_state
      t.datetime :remote_merged_at

      t.timestamps
    end
  end
end
