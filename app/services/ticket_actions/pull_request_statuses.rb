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
    @statuses ||=
      begin
        pull_request.repo
          .commit_statuses
          .where(sha: pull_request.remote_head_sha)
          .group_by(&:context)
          .map {|_, records| records.max_by(&:remote_created_at) }
      end
  end
end
