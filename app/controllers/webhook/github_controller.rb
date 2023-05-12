class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from AbstractController::ActionNotFound, with: :unhandled_event

  private

  def github_installation(payload)
    InstallationImporter.import(payload)
  end

  alias_method :github_installation_repositories, :github_installation

  def github_issues(payload)
    repo.with_lock do
      Ticket.import(payload[:issue], repo, action: payload[:action])
    end
  end

  def github_issue_comment(payload)
    Comment.import(payload, repo)
  end

  def github_push(payload)
    PushImporter.import(payload, repo)
  end

  def github_pull_request(payload)
    pull_request = repo.with_lock { PullRequest.import(payload[:pull_request], repo) }

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

  def webhook_secret(payload)
    if payload[:installation].present? || app_ping?
      ENV['GITHUB_APP_WEBHOOK_SECRET']
    else
      ENV['GITHUB_WEBHOOK_SECRET']
    end
  end

  def app_ping?
    request.headers['X-GitHub-Event'] == 'ping' && /^App/i.match?(json_body[:hook][:type])
  end

  def repo
    @repo ||= Repo.find_by!(remote_id: json_body[:repository][:id])
  end
end
