json.extract! @board, :id, :name

json.swimlanes @board.swimlanes.each do |swimlane|
  board_tickets = swimlane.first_board_tickets

  json.extract! swimlane, :id, :name
  json.display_duration swimlane.display_duration?
  json.next_board_tickets_url next_swimlane_tickets_path(board_tickets)
  json.all_board_tickets_loaded Swimlane.all_board_tickets_loaded?(board_tickets)

  json.board_tickets(
    board_tickets,
    partial: 'board_tickets/board_ticket',
    as: :board_ticket,
    locals: { swimlane: swimlane }
  )
end
