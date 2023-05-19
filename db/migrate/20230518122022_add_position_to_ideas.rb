class AddPositionToIdeas < ActiveRecord::Migration[6.0]
  def change
    add_column :ideas, :position, :integer
  end
end
