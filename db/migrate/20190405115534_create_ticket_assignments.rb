class CreateTicketAssignments < ActiveRecord::Migration[5.1]
  def change
    create_table :ticket_assignments do |t|
      t.references :ticket, foreign_key: true
      t.references :assignee_remote, foreign_key: false
      t.string :assignee_username

      t.timestamps
    end
  end
end
