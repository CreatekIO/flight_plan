class CreateBranches < ActiveRecord::Migration[5.1]
  def change
    create_table :branches do |t|
      t.references :repo, foreign_key: true
      t.string :name
      t.references :ticket, foreign_key: false
      t.string :base_ref
      t.references :latest_head, foreign_key: false

      t.timestamps
    end
    add_index :branches, %i[repo_id name]
    add_index :branches, %i[repo_id base_ref]
  end
end
