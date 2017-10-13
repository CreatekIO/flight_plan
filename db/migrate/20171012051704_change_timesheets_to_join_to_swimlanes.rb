class ChangeTimesheetsToJoinToSwimlanes < ActiveRecord::Migration[5.1]
  def change
    remove_reference :timesheets, :ticket
    remove_column :timesheets, :state, :string
    remove_column :timesheets, :before_state, :string
    remove_column :timesheets, :after_state, :string

    add_reference :timesheets, :board_ticket
    add_reference :timesheets, :swimlane
    add_reference :timesheets, :before_swimlane, foreign_key: { to_table: :swimlanes }
    add_reference :timesheets, :after_swimlane, foreign_key: { to_table: :swimlanes }
  end
end
