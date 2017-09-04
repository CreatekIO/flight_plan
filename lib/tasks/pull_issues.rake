task :pull_issues => :environment do
  Octokit.issues('createkio/flight_plan').each do |issue|
    ticket = Ticket.find_or_initialize_by(remote_id: issue.id)
    ticket.state = 'Backlog' unless ticket.persisted?
    ticket.update_attributes(
      remote_number: issue.number,
      remote_title: issue.title,
      remote_body: issue.body,
      remote_state: issue.state
    )
  end
end
