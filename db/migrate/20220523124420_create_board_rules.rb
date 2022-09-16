class CreateBoardRules < ActiveRecord::Migration[5.2]
  def change
    create_table :board_rules do |t|
      t.references :board, foreign_key: true, index: true, null: false
      t.string :rule_class, null: false
      t.boolean :enabled, default: true, null: false
      t.jsonb :settings, default: {}, null: false

      t.timestamps
    end
  end
end
