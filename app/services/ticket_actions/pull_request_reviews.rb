class TicketActions::PullRequestReviews < TicketActions::Base
  def next_action
    if reviews.none?
      # everyone
      positive 'Add a review', urls: "#{pull_request.html_url}/files"
    elsif superceded_reviews.any?
      # reviewers
      warning 'Re-review updates', urls: pull_request.html_url
    elsif pending_reviews.any?
      # owner
      warning 'Address changes', urls: pull_request.html_url
    end
  end

  private

  def reviews
    @reviews ||= pull_request.latest_reviews.reject do |review|
      review.reviewer_remote_id == pull_request.creator_remote_id && review.approved?
    end
  end

  def pending_reviews
    @pending_reviews ||= reviews.select(&:changes_requested?)
  end

  # Assumes users always review latest commit
  def superceded_reviews
    @superceded_reviews ||= pending_reviews.select do |review|
      pull_request.remote_head_sha != review.sha
    end
  end
end
