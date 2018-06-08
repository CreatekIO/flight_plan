class CreateBranchHeads < ActiveRecord::Migration[5.1]
  def change
    create_table :branch_heads do |t|
      t.references :repo, foreign_key: true
      t.references :branch, foreign_key: false
      t.string :branch_name
      t.string :head_sha
      t.string :previous_head_sha
      t.integer :commits_in_push
      t.boolean :force_push, default: false
      t.datetime :commit_timestamp
      t.string :author_username
      t.string :committer_username
      t.integer :pusher_remote_id
      t.string :pusher_username
      t.text :payload

      t.timestamps
    end
    add_index :branch_heads, %i[repo_id head_sha], unique: true
    add_index :branch_heads, :branch_name
    add_index :branch_heads, :author_username
    add_index :branch_heads, :committer_username
    add_index :branch_heads, :pusher_remote_id
  end
end
