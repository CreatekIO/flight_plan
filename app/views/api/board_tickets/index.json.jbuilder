json.array! @board_tickets do |board_ticket|
  json.id board_ticket.id
  json.board board_ticket.board.to_builder
  json.ticket board_ticket.ticket.to_builder
  json.swimlane board_ticket.swimlane.to_builder
end
