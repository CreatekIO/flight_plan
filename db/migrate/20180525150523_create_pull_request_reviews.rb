class CreatePullRequestReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :pull_request_reviews do |t|
      t.integer :remote_id
      t.references :repo, foreign_key: true
      t.integer :remote_pull_request_id
      t.string :state
      t.string :sha
      t.text :body
      t.string :url
      t.integer :reviewer_remote_id
      t.string :reviewer_username
      t.datetime :remote_created_at
      t.text :payload

      t.timestamps
    end
    add_index :pull_request_reviews, :remote_pull_request_id
    add_index :pull_request_reviews, :state
    add_index :pull_request_reviews, :sha
    add_index :pull_request_reviews, :reviewer_remote_id
  end
end
