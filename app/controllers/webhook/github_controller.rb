class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def github_issues(payload)
    Repo.find_by!(remote_url: payload[:repository][:full_name]).with_lock do
      Ticket.import(payload[:issue], payload[:repository])
    end
  end

  def github_issue_comment(payload)
    if payload[:action] == 'deleted'
      comment = Comment.find_by_remote(payload[:comment])
      comment.destroy if comment.persisted?
    else
      Comment.import(payload[:comment], payload[:issue], payload[:repo])
    end
  end

  def github_push(payload)
    repo = Repo.find_by!(remote_url: payload['repository']['full_name']) 

    issue_number = payload['ref'][/#[0-9]*/, 0]
    if issue_number
      ticket = repo.tickets.find_by!(remote_number: issue_number[1..-1])
      ticket.update_attributes(merged: false)
    elsif payload['ref'] == 'refs/heads/master'
      repo.update_merged_tickets
    end
  end

  def not_found
    head :ok
  end

  def webhook_secret(_payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
