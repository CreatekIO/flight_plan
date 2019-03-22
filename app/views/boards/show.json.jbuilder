json.extract! @board, :id, :name

json.swimlanes @board.preloaded_board_tickets.chunk(&:swimlane).each do |(swimlane, board_tickets)|
  json.extract! swimlane, :id, :name
  json.display_duration swimlane.display_duration?
  json.next_board_tickets_url swimlane_tickets_path(swimlane, page: next_page)
  json.all_board_tickets_loaded @board.all_board_tickets_loaded?(board_tickets)

  json.board_tickets(
    board_tickets, partial: 'board_tickets/board_ticket', as: :board_ticket, locals: { swimlane: swimlane }
  )
end
