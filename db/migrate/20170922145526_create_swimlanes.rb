class CreateSwimlanes < ActiveRecord::Migration[5.1]
  def change
    create_table :swimlanes do |t|
      t.references :board
      t.string :name
      t.integer :position
      t.boolean :display_duration

      t.timestamps
    end
  end
end
