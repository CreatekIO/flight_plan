json.id @board_ticket.id
json.state_durations @board_ticket.displayable_durations(@board)

json.ticket do
  ticket = @board_ticket.ticket 
  json.id ticket.id
  json.title ticket.remote_title
  json.body simple_format(ticket.remote_body)

  json.comments(ticket.comments) do |comment|
    json.id comment.id
    json.body simple_format(comment.remote_body)
    json.author comment.remote_author
  end
end
