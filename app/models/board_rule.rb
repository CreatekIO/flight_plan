class BoardRule < ApplicationRecord
  belongs_to :board

  validates :rule_class, presence: true, inclusion: { in: :available_rules, allow_blank: true }

  private

  def available_rules
    ApplicationRule.descendants.map(&:name)
  end
end
