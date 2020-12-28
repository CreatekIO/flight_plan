class MassRenameColumns < ActiveRecord::Migration[5.1]
  def change
    return say('Not running on MySQL') if connection.adapter_name == 'MySQL'

    change_table :comments do |t|
      t.rename :remote_body, :body
      t.rename :remote_author_id, :author_remote_id
      t.rename :remote_author, :author_username
    end

    change_table :milestones do |t|
      t.rename :remote_number, :number
    end

    change_table :pull_requests do |t|
      %i[number title body state head_branch head_sha base_branch].each do |column|
        t.rename :"remote_#{column}", column
      end
    end

    change_table :repos do |t|
      t.rename :remote_url, :slug
    end

    change_table :tickets do |t|
      t.remove :state

      %i[number title body state].each do |column|
        t.rename :"remote_#{column}", column
      end
    end
  end
end
