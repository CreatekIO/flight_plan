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
    change_collations 'utf8mb4_general_ci'
  end

  # By omitting the collation we reset it back to the table/database default
  def down
    change_collations nil
  end

  private

  def change_collations(collation)
    COLUMNS_TO_CHANGE.each do |table, columns|
      columns.each do |column|
        change_column table, column, :string, collation: collation
      end
    end
  end
end
