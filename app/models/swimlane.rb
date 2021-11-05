class Swimlane < ApplicationRecord
  BOARD_TICKET_PRELOAD_LIMIT = 10

  belongs_to :board

  has_many :board_tickets, -> { rank(:swimlane_sequence) }, dependent: :destroy do
    def after(seq)
      where(arel_table[:swimlane_sequence].gt(seq))
    end

    def rebalance!
      # Extracted from ranked-model gem
      ids = current_scope.pluck(:id)
      gaps = ids.size + 1
      range = (RankedModel::MAX_RANK_VALUE - RankedModel::MIN_RANK_VALUE).to_f
      gap_size = (range / gaps).ceil

      ids.each.with_index(1) do |id, position|
        new_rank = (gap_size * position) + RankedModel::MIN_RANK_VALUE

        BoardTicket.unscoped.where(id: id).update_all(swimlane_sequence: new_rank)
      end
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
    where(name: label.remove(/^#{Label::STATUS_PREFIX}/)).first!
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

  def label_name
    "#{Label::STATUS_PREFIX}#{name.downcase}"
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
