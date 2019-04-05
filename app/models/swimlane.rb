class Swimlane < ApplicationRecord
  BOARD_TICKET_PRELOAD_LIMIT = 10

  belongs_to :board

  has_many :board_tickets, -> { rank(:swimlane_sequence) }, dependent: :destroy do
    def after(seq)
      where(arel_table[:swimlane_sequence].gt(seq))
    end
  end
  has_many(
    :first_board_tickets,
    -> { rank(:swimlane_sequence).limit(BOARD_TICKET_PRELOAD_LIMIT).preloaded },
    class_name: 'BoardTicket'
  )
  has_many :tickets, through: :board_tickets
  has_many :swimlane_transitions, -> { order(:position) }, dependent: :destroy
  has_many :transitions, through: :swimlane_transitions

  scope :ordered, -> { order(:position) }

  def self.find_by_label!(label)
    where('LOWER(name) = ?', label.gsub(/^status: /, '')).first!
  end

  def self.all_board_tickets_loaded?(collection)
    collection.length < BOARD_TICKET_PRELOAD_LIMIT
  end

  def first_board_tickets
    board_tickets.limit(BOARD_TICKET_PRELOAD_LIMIT).preloaded
  end

  def preloaded_board_tickets(after:)
    first_board_tickets.after(after)
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
