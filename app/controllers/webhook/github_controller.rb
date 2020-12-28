class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from NoMethodError, with: :unhandled_event

  private

  def github_issues(payload)
    repo.with_lock do
      Ticket.import(payload[:issue], payload[:repository], action: payload[:action])
    end
  end

  def github_issue_comment(payload)
    Comment.import(payload, repo)
  end

  def github_push(payload)
    PushImporter.import(payload, repo)
  end

  def github_pull_request(payload)
    pull_request = repo.with_lock { PullRequest.import(payload[:pull_request], payload[:repository]) }

    PullRequestRefreshWorker.update_after_import(pull_request)
  end

  def github_status(payload)
    CommitStatus.import(payload, repo)
  end

  def github_pull_request_review(payload)
    PullRequestReview.import(payload, repo)
  end

  def not_found
    head :ok
  end

  def unhandled_event(error)
    return head :ok if error.message.include?('GithubWebhooksController')

    raise error
  end

  def webhook_secret(_payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end

  def repo
    @repo ||= Repo.find_by!(slug: json_body[:repository][:full_name])
  end
end
