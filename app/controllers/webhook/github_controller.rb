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

  def not_found
    head :not_found
  end

  def webhook_secret(_payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end

end
