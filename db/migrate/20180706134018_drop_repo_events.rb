class DropRepoEvents < ActiveRecord::Migration[5.1]
  def up
    drop_table :repo_events
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'cannnot restore table data'
  end
end
