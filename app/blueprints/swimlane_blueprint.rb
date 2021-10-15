class SwimlaneBlueprint < ApplicationBlueprint
  field :name
  field :display_duration?, name: :display_duration

  association_ids :board_tickets

  field :all_board_tickets_loaded do |swimlane|
    Swimlane.all_board_tickets_loaded?(swimlane.preloaded_board_ticket_ids)
  end

  field :next_board_tickets_url do |swimlane, options|
    last = swimlane.preloaded_board_ticket_ids.last
    next if last.blank?

    board_ticket = options.dig(:records, BoardTicket, last)

    Rails.application.routes.url_helpers.swimlane_tickets_path(
      swimlane.id,
      after: board_ticket.swimlane_sequence
    )
  end
end
