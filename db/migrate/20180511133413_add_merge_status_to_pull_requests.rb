class AddMergeStatusToPullRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :pull_requests, :merge_status, :string
    add_index :pull_requests, :merge_status
  end
end
