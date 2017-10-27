class AddAutoDeploySwimlaneToBoard < ActiveRecord::Migration[5.1]
  def change
    add_column :boards, :deploy_swimlane_id, :integer
    add_column :boards, :auto_deploy, :boolean, null: false, default: false
    add_column :boards, :next_deployment, :datetime
  end
end
