class CreatePullRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :pull_requests do |t|
      t.string :remote_id
      t.string :remote_number
      t.string :remote_title
      t.text :remote_body
      t.string :remote_state
      t.string :remote_head_branch
      t.string :remote_head_sha
      t.string :remote_base_branch
      t.references :repo, foreign_key: true

      t.timestamps
    end
  end
end
