class CreateRepos < ActiveRecord::Migration[5.1]
  def change
    create_table :repos do |t|
      t.string :name
      t.string :remote_url

      t.timestamps
    end
  end
end
