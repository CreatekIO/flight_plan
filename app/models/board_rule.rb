class BoardRule < ApplicationRecord
  belongs_to :board

  scope :enabled, -> { where(enabled: true) }

  validates :rule_class, presence: true, inclusion: { in: :available_rules, allow_blank: true }

  def self.for(board:, rule:)
    return if board.blank?

    find_by(board: board, rule_class: rule.name)
  end

  private

  def available_rules
    ApplicationRule.descendants.map(&:name)
  end
end
