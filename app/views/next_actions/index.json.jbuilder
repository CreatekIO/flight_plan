json.array! @repos do |repo|
  json.extract! repo, :id, :name

  json.pull_requests repo.open_pull_requests do |pull_request|
    json.extract! pull_request, :id

    json.repo repo.id

    json.next_action(
      TicketActions.next_action_for(pull_request, user: current_user)
    )
  end
end
