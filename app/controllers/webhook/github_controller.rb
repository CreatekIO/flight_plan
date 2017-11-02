class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def github_issues(payload)
    Ticket.import(payload[:issue], payload[:repository])
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
    issue_number = payload['ref'][/#[0-9]*/, 0][1..-1]
    return unless issue_number

    repo = Repo.find_by!(remote_url: payload['repository']['full_name']) 
    ticket = repo.tickets.find_by!(remote_number: issue_number)

    ticket.update_attributes(merged: false)
  end

  def not_found
    head :ok
  end

  def webhook_secret(_payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
