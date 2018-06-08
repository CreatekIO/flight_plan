class CreateCommitStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :commit_statuses do |t|
      t.integer :remote_id
      t.references :repo, foreign_key: true
      t.string :state
      t.string :sha
      t.text :description
      t.string :context
      t.string :url
      t.string :avatar_url
      t.integer :author_remote_id
      t.string :author_username
      t.integer :committer_remote_id
      t.string :committer_username
      t.datetime :remote_created_at
      t.text :payload

      t.timestamps
    end
    add_index :commit_statuses, :state
    add_index :commit_statuses, :sha
    add_index :commit_statuses, :author_remote_id
    add_index :commit_statuses, :committer_remote_id
  end
end
