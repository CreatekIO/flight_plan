class CreateTickets < ActiveRecord::Migration[5.1]
  def change
    create_table :tickets do |t|
      t.string :remote_id
      t.string :remote_number
      t.string :remote_title
      t.text :remote_body
      t.string :remote_state
      t.string :state
      t.timestamps
    end
  end
end
