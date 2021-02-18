class BranchHead < ApplicationRecord
  belongs_to :branch

  self.ignored_columns = %w[payload]

  NULL_SHA = '0000000000000000000000000000000000000000'.freeze

  def previous_head_sha=(value)
    value = nil if value == NULL_SHA

    super(value)
  end
end
