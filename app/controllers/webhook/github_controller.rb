class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from NoMethodError, with: :unhandled_event

  private

  def github_issues(payload)
    repo.with_lock do
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
    issue_number = IssueNumberExtractor.from_branch(payload[:ref])

    if issue_number
      ticket = repo.tickets.find_by!(remote_number: issue_number)
      ticket.update_attributes(merged: false)
    elsif payload[:ref] == 'refs/heads/master'
      repo.update_merged_tickets
    end
  end

  def github_pull_request(payload)
    repo.with_lock do
      PullRequest.import(payload[:pull_request], payload[:repository])
    end
  end

  def github_status(payload)
    RepoEvent::Status.import(payload, repo)
  end

  def github_pull_request_review(payload)
    RepoEvent::PullRequestReview.import(payload, repo)
  end

  def not_found
    head :ok
  end

  def unhandled_event(error)
    if error.message.include?('GithubWebhooksController')
      head :ok
    else
      raise error
    end
  end

  def webhook_secret(_payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end

  def repo
    @repo ||= Repo.find_by!(remote_url: json_body[:repository][:full_name])
  end
end
