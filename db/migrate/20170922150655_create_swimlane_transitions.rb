class CreateSwimlaneTransitions < ActiveRecord::Migration[5.1]
  def change
    create_table :swimlane_transitions do |t|
      t.references :swimlane
      t.integer :transition_id
      t.integer :position

      t.timestamps
    end
  end
end
