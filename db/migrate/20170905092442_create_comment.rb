class CreateComment < ActiveRecord::Migration[5.1]
  def change
    create_table :comments do |t|
      t.references :tickets
      t.timestamps
    end
  end
end
