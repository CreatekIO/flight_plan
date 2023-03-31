ticket = @board_ticket.ticket
milestone = ticket.milestone

json.id @board_ticket.id
json.state_durations @board_ticket.displayable_durations(@board)

json.ticket do
  json.extract! ticket, :id, :number, :title, :html_url
  json.state ticket.state
  json.creator ticket.creator_username || 'ghost'
  json.body ticket.body
  json.timestamp time_ago_in_words(ticket.remote_created_at || ticket.created_at)

  json.repo do
    json.extract! ticket.repo, :id, :name, :slug
    json.uses_app ticket.repo.uses_app?
  end
end

json.pull_requests ticket.pull_requests.includes(:repo) do |pull_request|
  json.extract!(
    pull_request,
    :id,
    :number,
    :title,
    :state,
    :merged,
    :html_url
  )
  json.repo do
    json.extract! pull_request.repo, :id, :name, :slug
    json.uses_app ticket.repo.uses_app?
  end
end

json.labels ticket.display_labels do |label|
  json.merge! label.to_builder.attributes!
end

if milestone.present?
  json.milestone do
    json.extract! milestone, :id, :title
    json.repo milestone.repo_id
  end
end

json.assignees ticket.assignments do |assignment|
  json.remote_id assignment.assignee_remote_id
  json.username assignment.assignee_username
end

json.comments(ticket.comments) do |comment|
  json.id comment.id
  json.body comment.body
  json.author comment.author_username
  json.timestamp time_ago_in_words(comment.remote_created_at || comment.created_at)
end
