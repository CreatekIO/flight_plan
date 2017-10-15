class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def github_ping(paylog)
    p paylog
  end

  def github_issues(payload)
    Ticket.import_from_remote(payload[:issue], payload[:repository])
  end

  def github_issue_comment(payload)
    Comment.import_from_remote(payload[:comment], payload[:issue], payload[:repo])
  end

  def not_found
    head :not_found
  end

  def webhook_secret(_payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end

end
