class AddStatusToIdeas < ActiveRecord::Migration[6.0]
  def change
    add_column :ideas, :status, :string, default: 'pending'
  end
end
