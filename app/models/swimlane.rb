class Swimlane < ApplicationRecord
  belongs_to :board

  has_many :board_tickets, -> { rank(:swimlane_sequence) }, dependent: :destroy
  has_many :tickets, through: :board_tickets
  has_many :swimlane_transitions, -> { order(:position) }, dependent: :destroy
  has_many :transitions, through: :swimlane_transitions

  scope :ordered, -> { order(:position) }

  def self.find_by_label!(label)
    where('LOWER(name) = ?', label.gsub(/^status: /, '')).first!
  end

  def to_builder
    Jbuilder.new do |swimlane|
      swimlane.id id
      swimlane.name name
      swimlane.position position
      swimlane.display_duration display_duration
    end
  end
end
