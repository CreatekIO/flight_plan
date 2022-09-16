class BoardRule < ApplicationRecord
  belongs_to :board

  scope :enabled, -> { where(enabled: true) }

  validates :rule_class, presence: true, inclusion: { in: :available_rules, allow_blank: true }

  def self.for(board:, rule:)
    return null if board.blank?

    find_by(board: board, rule_class: rule.name) || null
  end

  def self.null
    new(enabled: false, settings: {}).tap(&:readonly!)
  end

  def setting(name, default = nil, &block)
    args = [name.to_s.chomp('?')]
    args << default unless block_given?

    settings.fetch(*args, &block)
  end

  private

  def available_rules
    ApplicationRule.descendants.map(&:name)
  end
end
