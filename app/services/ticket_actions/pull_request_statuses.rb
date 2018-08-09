class TicketActions::PullRequestStatuses < TicketActions::Base
  def next_action
    if failed_statuses.any?
      # owner
      negative 'Fix issues', urls: to_urls(failed_statuses)
    elsif pending_statuses.any?
      # owner
      neutral 'Wait for checks', urls: to_urls(pending_statuses)
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

  def to_urls(records)
    records.map do |record|
      { title: record.description, url: record.url }
    end
  end
end
