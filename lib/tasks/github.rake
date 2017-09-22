namespace :github do
  task :pull => :environment do
    Repo.find_or_create_by(name: 'FlightPlan', remote_url: 'CreatekIO/flight_plan')
    Repo.find_or_create_by(name: 'MyRewards', remote_url: 'CorporateRewards/myrewards')
    Repo.find_or_create_by(name: 'GPS', remote_url: 'CorporateRewards/redstone')

    Repo.all.each do |repo|
      Octokit.issues(repo.remote_url).each do |issue|
        ticket = Ticket.find_or_initialize_by(remote_id: issue.id)
        ticket.state = 'Backlog' unless ticket.persisted?
        ticket.update_attributes(
          remote_number: issue.number,
          remote_title: issue.title,
          remote_body: issue.body,
          remote_state: issue.state,
          repo_id: repo.id
        )

        Octokit.issue_comments(repo.remote_url, issue.number).each do |issue_comment|
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
  end
end
