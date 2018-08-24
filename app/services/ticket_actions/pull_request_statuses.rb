class TicketActions::PullRequestStatuses < TicketActions::Base
  def next_action
    if failed_statuses.any?
      # owner
      negative 'Fix issues', urls: failed_statuses.map(&:url)
    elsif pending_statuses.any?
      # owner
      neutral 'Wait for checks', urls: pending_statuses.map(&:url)
    end
  end

  private

  def pending_statuses
    @pending_statuses ||= statuses.select(&:pending?)
  end

  def failed_statuses
    @failed_statuses ||= statuses.select(&:unsuccessful?)
  end

  def statuses
    @commit_statuses ||= pull_request.latest_commit_statuses
  end
end
