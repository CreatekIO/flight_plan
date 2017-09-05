class CreateTimesheet < ActiveRecord::Migration[5.1]
  def change
    create_table :timesheets do |t|
      t.references :ticket
      t.datetime :started_at
      t.datetime :ended_at
      t.string :state
      t.string :before_state
      t.string :after_state
      t.timestamps
    end
  end
end
