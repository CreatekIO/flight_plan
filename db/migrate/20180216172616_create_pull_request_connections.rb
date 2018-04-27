class CreatePullRequestConnections < ActiveRecord::Migration[5.1]
  def change
    create_table :pull_request_connections do |t|
      t.references :ticket, foreign_key: true
      t.references :pull_request, foreign_key: true

      t.timestamps
    end
  end
end
