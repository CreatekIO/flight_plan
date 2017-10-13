class Swimlane < ApplicationRecord
  belongs_to :board

  has_many :board_tickets, dependent: :destroy
  has_many :tickets, through: :board_tickets
  has_many :swimlane_transitions, dependent: :destroy
  has_many :transitions, through: :swimlane_transitions

  def self.find_by_label!(label)
    where('LOWER(name) = ?', label.gsub(/^status: /, '')).first!
  end
end
