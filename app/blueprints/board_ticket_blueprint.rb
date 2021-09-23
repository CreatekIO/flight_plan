class BoardTicketBlueprint < ApplicationBlueprint
  field :ticket_id, name: :ticket
  field :swimlane_id, name: :swimlane # required?

  field :latest_timesheet do |board_ticket|
    board_ticket.preloaded_timesheet_ids.first
  end

  field :url do |board_ticket, options|
    Rails.application.routes.url_helpers.board_ticket_path(
      board_ticket.board_id,
      board_ticket
    )
  end

  # Compatibility
  field(
    :time_since_last_transition,
    if: -> (_, board_ticket, options) {
      options.dig(:records, Swimlane, board_ticket.swimlane_id).display_duration?
    }
  ) do |board_ticket, options|
    timesheet = options.dig(:records, Timesheet, board_ticket.preloaded_timesheet_ids.first)

    Timesheet.format_duration(timesheet.duration)
  end
end
