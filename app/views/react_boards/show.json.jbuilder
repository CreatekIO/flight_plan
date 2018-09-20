json.array! @swimlanes do |swimlane|
  json.extract! swimlane, :id, :name, :display_duration

  json.board_tickets swimlane.board_tickets do |board_ticket|
    ticket = board_ticket.ticket

    json.id board_ticket.id
    json.current_state_duration '1d' # board_ticket.current_state_duration
    json.ticket do
      json.extract! ticket, :id, :remote_number, :remote_title, :html_url
      json.repo do
        json.extract! ticket.repo, :name
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
      json.next_action(
        TicketActions.next_action_for(pull_request, user: current_user)
      )
    end
  end
end
