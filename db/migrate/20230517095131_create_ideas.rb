class CreateIdeas < ActiveRecord::Migration[6.0]
  def change
    create_table :ideas do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.references :submitter, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
