class CreateMilestones < ActiveRecord::Migration[5.1]
  def change
    create_table :milestones do |t|
      t.bigint :remote_id
      t.bigint :remote_number
      t.string :title
      t.string :state
      t.text :description
      t.datetime :due_on
      t.references :repo, index: true, foreign_key: true

      t.timestamps
    end
    add_index :milestones, :remote_id
  end
end
