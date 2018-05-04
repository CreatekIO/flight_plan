class CreateRepoEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :repo_events do |t|
      t.string :type, null: false
      t.references :repo, foreign_key: true
      t.references :user, type: :string, foreign_key: false
      t.string :username
      t.references :record, polymorphic: true
      t.string :action
      t.string :state
      t.string :branch
      t.string :sha
      t.string :url
      t.string :context

      t.timestamps
    end
    add_index :repo_events, [:id, :type]
    add_index :repo_events, :action
    add_index :repo_events, :state
  end
end