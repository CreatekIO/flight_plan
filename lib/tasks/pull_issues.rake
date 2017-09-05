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

    Octokit.issue_comments('createkio/flight_plan', issue.number).each do |issue_comment|
      comment = Comment.find_or_initialize_by(remote_id: issue_comment.id)
      comment.update_attributes(
        ticket_id: ticket.id,
        remote_body: issue_comment.body,
        remote_author_id: issue_comment.user.id,
        remote_author: issue_comment.user.login
      )
    end
  end
end
