class AddLimitToShaColumns < ActiveRecord::Migration[5.1]
  SHA_SIZE = 40 # SHA1 (160 bits) as hex = 40 chars

  COLUMNS_TO_CHANGE = {
    branch_heads: %i[head_sha previous_head_sha],
    commit_statuses: %i[sha],
    pull_request_reviews: %i[sha],
    pull_requests: %i[remote_head_sha]
  }.freeze

  def up
    change_limits_to(SHA_SIZE)
  end

  def down
    change_limits_to(nil) # remove
  end

  private

  def change_limits_to(limit)
    COLUMNS_TO_CHANGE.each do |table, columns|
      columns.each do |column|
        change_column table, column, :string, limit: limit
      end
    end
  end
end
