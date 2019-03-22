json.extract! @swimlane, :id
json.next_board_tickets_url swimlane_tickets_path(@swimlane, page: next_page)
json.all_board_tickets_loaded @board.all_board_tickets_loaded?(@board_tickets)

json.board_tickets(
  @board_tickets, partial: 'board_tickets/board_ticket', as: :board_ticket, locals: { swimlane: @swimlane }
)
