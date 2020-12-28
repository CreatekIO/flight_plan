class SwitchAllIdColumnsToBigInt < ActiveRecord::Migration[5.1]
  COLUMNS_TO_CHANGE = {
    boards: %i[deploy_swimlane_id],
    branch_heads: %i[pusher_remote_id],
    commit_statuses: %i[author_remote_id committer_remote_id],
    comments: %i[remote_id remote_author_id],
    labels: %i[remote_id],
    pull_request_reviews: %i[remote_id remote_pull_request_id reviewer_remote_id],
    pull_requests: %i[remote_id],
    repo_releases: %i[remote_id remote_number],
    swimlane_transitions: %i[transition_id],
    tickets: %i[remote_id creator_remote_id]
  }.freeze

  STRING_COLUMNS = %w[
    comments#remote_id comments#remote_author_id
    pull_requests#remote_id tickets#remote_id
  ]

  def up
    return say('Not running on MySQL') if connection.adapter_name == 'Mysql2'

    COLUMNS_TO_CHANGE.each do |table, columns|
      columns.each do |column|
        change_column table, column, :bigint, cast_as: :integer
      end
    end
  end

  def down
    return say('Not running on MySQL') if connection.adapter_name == 'Mysql2'

    COLUMNS_TO_CHANGE.each do |table, columns|
      columns.each do |column|
        type = string_column?(table, column) ? :string : :integer

        change_column table, column, type
      end
    end
  end

  private

  def string_column?(table, column)
    STRING_COLUMNS.include?("#{table}##{column}")
  end
end
