json.id @board_ticket.id
json.state_durations @board_ticket.displayable_durations(@board)

json.ticket do
  ticket = @board_ticket.ticket
  json.id ticket.id
  json.number ticket.remote_number
  json.html_url ticket.html_url
  json.title ticket.remote_title
  json.body ticket.remote_body
  json.timestamp time_ago_in_words(ticket.created_at)

  json.comments(ticket.comments) do |comment|
    json.id comment.id
    json.body comment.remote_body
    json.author comment.remote_author
    json.timestamp time_ago_in_words(comment.created_at)
  end
end
