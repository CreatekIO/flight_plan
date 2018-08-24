class AddMergedToPullRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :pull_requests, :merged, :boolean, default: false
    add_index :pull_requests, :merged
  end
end
