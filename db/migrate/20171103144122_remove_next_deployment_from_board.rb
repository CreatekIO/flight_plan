class RemoveNextDeploymentFromBoard < ActiveRecord::Migration[5.1]
  def change
    remove_column :boards, :next_deployment, :datetime
  end
end
