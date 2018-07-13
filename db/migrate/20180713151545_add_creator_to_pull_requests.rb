class AddCreatorToPullRequests < ActiveRecord::Migration[5.1]
  def change
    add_reference :pull_requests, :creator_remote, foreign_key: false
    add_column :pull_requests, :creator_username, :string
  end
end
