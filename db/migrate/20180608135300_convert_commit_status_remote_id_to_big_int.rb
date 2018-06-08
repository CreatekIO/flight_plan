class ConvertCommitStatusRemoteIdToBigInt < ActiveRecord::Migration[5.1]
  def up
    change_column :commit_statuses, :remote_id, :bigint
  end

  def down
    change_column :commit_statuses, :remote_id, :integer
  end
end
