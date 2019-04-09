ticket = @board_ticket.ticket
milestone = ticket.milestone

json.id @board_ticket.id
json.state_durations @board_ticket.displayable_durations(@board)

json.ticket do
  json.extract! ticket, :id, :remote_number, :remote_title, :html_url
  json.state ticket.remote_state
  json.creator ticket.creator_username || 'ghost'
  json.body ticket.remote_body
  json.timestamp time_ago_in_words(ticket.remote_created_at || ticket.created_at)

  json.repo do
    json.extract! ticket.repo, :id, :name
  end
end

json.pull_requests ticket.pull_requests do |pull_request|
  json.extract!(
    pull_request,
    :id,
    :remote_number,
    :remote_title,
    :remote_state,
    :merged,
    :html_url
  )
  json.repo pull_request.repo_id
end

json.labels ticket.display_labels do |label|
  json.extract! label, :id, :name, :colour
  json.repo label.repo_id
end

if milestone.present?
  json.milestone do
    json.extract! milestone, :id, :title
    json.repo milestone.repo_id
  end
end

json.comments(ticket.comments) do |comment|
  json.id comment.id
  json.body comment.remote_body
  json.author comment.remote_author
  json.timestamp time_ago_in_words(comment.remote_created_at || comment.created_at)
end
