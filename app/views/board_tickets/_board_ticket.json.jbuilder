ticket = board_ticket.ticket
milestone = ticket.milestone

json.id board_ticket.id
json.time_since_last_transition board_ticket.time_since_last_transition if swimlane.display_duration?
json.url board_ticket_path(@board, board_ticket)

json.ticket do
  json.extract! ticket, :id, :remote_number, :remote_title, :html_url
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

json.assignees ticket.assignments do |assignment|
  json.remote_id assignment.assignee_remote_id
  json.username assignment.assignee_username
end
