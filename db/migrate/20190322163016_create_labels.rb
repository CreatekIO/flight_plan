class CreateLabels < ActiveRecord::Migration[5.1]
  def change
    create_table :labels do |t|
      t.string :name
      t.integer :remote_id
      t.string :colour, limit: 6 # hex code, without the leading `#`
      t.references :repo, index: true, foreign_key: true

      t.timestamps
    end

    add_index :labels, :remote_id
  end
end
