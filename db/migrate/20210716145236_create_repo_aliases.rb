class CreateRepoAliases < ActiveRecord::Migration[5.2]
  def change
    create_table :repo_aliases do |t|
      t.references :repo, index: true, foreign_key: true
      t.citext :slug, index: { unique: true }

      t.timestamps null: false
    end
  end
end
