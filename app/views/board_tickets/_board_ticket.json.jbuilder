ticket = board_ticket.ticket

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