class AddRemoteInstallationIdToRepos < ActiveRecord::Migration[5.2]
  def change
    add_column :repos, :remote_installation_id, :bigint
  end
end
