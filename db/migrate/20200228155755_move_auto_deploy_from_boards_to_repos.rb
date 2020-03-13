class MoveAutoDeployFromBoardsToRepos < ActiveRecord::Migration[5.1]
  def change
    add_column :repos, :auto_deploy, :boolean, null: false, default: false
    remove_column :boards, :auto_deploy, :boolean, null: false, default: false
  end
end
