json.extract! @swimlane, :id
json.next_board_tickets_url next_swimlane_tickets_path(@board_tickets)
json.all_board_tickets_loaded Swimlane.all_board_tickets_loaded?(@board_tickets)

json.board_tickets(
  @board_tickets, partial: 'board_ticket', as: :board_ticket, locals: { swimlane: @swimlane }
)
