json.id @ticket.id
json.title @ticket.remote_title
json.body simple_format(@ticket.remote_body)
#todo: put this back in once ticket is routed via its board
#json.state_durations @ticket.displayable_durations
json.comments(@ticket.comments) do |comment|
  json.id comment.id
  json.body simple_format(comment.remote_body)
  json.author comment.remote_author
end
