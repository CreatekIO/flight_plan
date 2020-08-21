class SetCaseInsensitiveCollationForIdentifiers < ActiveRecord::Migration[5.1]
  COLUMNS_TO_CHANGE = {
    repos: %i[remote_url],
    users: %i[username],
    branch_heads: %i[author_username committer_username pusher_username],
    comments: %i[remote_author],
    commit_statuses: %i[author_username committer_username],
    labels: %i[name],
    pull_request_reviews: %i[reviewer_username],
    pull_requests: %i[creator_username],
    swimlanes: %i[name],
    ticket_assignments: %i[assignee_username],
    tickets: %i[creator_username]
  }

  def up
    case connection.adapter_name
    when 'Mysql2'
      change_collations 'utf8mb4_general_ci'
    when 'PostgreSQL'
      enable_extension :citext

      change_column_types :citext
    end
  end

  def down
    case connection.adapter_name
    when 'Mysql2'
      # By omitting the collation we reset it back to the table/database default
      change_collations nil
    when 'PostgreSQL'
      disable_extension :citext

      change_column_types :string
    end
  end

  private

  def change_collations(collation)
    COLUMNS_TO_CHANGE.each do |table, columns|
      columns.each do |column|
        change_column table, column, :string, collation: collation
      end
    end
  end

  def change_column_types(type)
    COLUMNS_TO_CHANGE.each do |table, columns|
      columns.each do |column|
        change_column table, column, type
      end
    end
  end
end
