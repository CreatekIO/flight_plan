class CreateComment < ActiveRecord::Migration[5.1]
  def change
    create_table :comments do |t|
      t.references :ticket
      t.text :remote_body
      t.string :remote_id
      t.string :remote_author_id
      t.string :remote_author
      t.timestamps
    end
  end
end
