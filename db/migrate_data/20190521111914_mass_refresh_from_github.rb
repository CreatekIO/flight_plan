class MassRefreshFromGithub < ActiveRecord::Migration["4.2"]
  def up
    return say 'Skipping as not on Heroku' if ENV['DYNO'].blank?

    time = Time.current.change(hour: 22) # 10pm tonight

    say_with_time "Enqueuing open tickets for refresh at #{time}" do
      Ticket.where(remote_state: 'open').pluck(:id).each do |ticket_id|
        TicketRefreshWorker.perform_at(time, ticket_id)
      end
    end

    time = Time.current.change(hour: 23) # 11pm tonight

    say_with_time "Enqueuing open PRs for refresh at #{time}" do
      PullRequest.open.pluck(:id).each do |pull_request_id|
        PullRequestRefreshWorker.perform_at(time, pull_request_id)
      end
    end
  end
end
