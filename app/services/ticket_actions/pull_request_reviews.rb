class TicketActions::PullRequestReviews < TicketActions::Base
  next_actions do |c|
    if reviews.none?
      # everyone but owner
      c.positive('Add a review', urls: "#{html_url}/files", user_ids: team_ids, priority: 10)
      c.neutral('Wait for a review', urls: html_url, user_ids: owner_id)
    else
      if superceded_reviews.any?
        # reviewers
        reviewer_ids = still_pending_reviews.map(&:reviewer_remote_id)

        c.warning('Re-review updates', urls: html_url, user_ids: reviewer_ids, priority: 10)
        c.caution('Wait for reviewers', urls: html_url, user_ids: team_ids(except: reviewer_ids))
      end

      if still_pending_reviews.any?
        # owner
        c.warning('Address changes', urls: html_url, user_ids: owner_id)
        c.caution('Wait for changes', urls: html_url, user_ids: team_ids)
      end
    end
  end

  private

  def reviews
    @reviews ||= pull_request.latest_reviews.reject do |review|
      review.reviewer_remote_id == pull_request.creator_remote_id && review.approved?
    end
  end

  def pending_reviews
    @pending_reviews ||= reviews.select(&:changes_requested?).group_by do |review|
      superceded?(review) ? :superceded : :still_pending
    end
  end

  def still_pending_reviews
    @still_pending_reviews ||= pending_reviews.fetch(:still_pending, [])
  end

  def superceded_reviews
    @superceded_reviews ||= pending_reviews.fetch(:superceded, [])
  end

  # Assumes users always review latest commit
  def superceded?(review)
    pull_request.remote_head_sha != review.sha
  end
end
