json.id @ticket.id
json.title @ticket.remote_title
json.body @ticket.remote_body
json.comments(@ticket.comments) do |comment|
  json.id comment.id
  json.body comment.remote_body
  json.author comment.remote_author
end
