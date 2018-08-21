class TicketActions::PullRequestStatuses < TicketActions::Base
  next_actions do |c|
    if failed_statuses.any?
      # owner
      c.negative 'Fix issues', urls: to_urls(failed_statuses), user_ids: owner_id
      c.warning 'Failed checks', urls: to_urls(failed_statuses), user_ids: team_ids
    elsif pending_statuses.any?
      # everyone
      c.neutral 'Wait for checks', urls: to_urls(pending_statuses)
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
    @statuses ||= pull_request.latest_commit_statuses.reject {|status| ignore?(status) }
  end

  def ignore?(status)
    config.fetch(:ignored_contexts, []).include?(status.context)
  end

  def to_urls(records)
    records.map do |record|
      { title: record.description, url: record.url }
    end
  end
end
