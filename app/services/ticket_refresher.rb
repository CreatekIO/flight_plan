class TicketRefresher
  include OctokitClient

  delegate :repo, to: :ticket

  octokit_methods :issue, :issue_comments, prefix_with: %w[repo.slug ticket.number]

  def initialize(ticket)
    @ticket = ticket
  end

  def run
    update_ticket
    update_ticket_comments
    update_linked_pull_requests
  end

  private

  attr_reader :ticket

  def update_ticket
    @ticket = Ticket.import(gh_ticket, full_name: repo.slug)
  end

  def update_ticket_comments
    octokit_issue_comments.each do |gh_comment|
      Comment.import({ comment: gh_comment.to_hash, issue: gh_ticket }, repo)
    end
  end

  def update_linked_pull_requests
    ticket.pull_request_ids.each do |id|
      PullRequestRefreshWorker.perform_async(id)
    end
  end

  def gh_ticket
    @gh_ticket ||= octokit_issue.to_hash
  end
end
