class PullRequestReview < ApplicationRecord
  belongs_to :repo
  belongs_to :pull_request, optional: true,
    foreign_key: :remote_pull_request_id, primary_key: :remote_id
  belongs_to :reviewer, -> { where(provider: 'github') },
    optional: true, class_name: 'User',
    foreign_key: :reviewer_remote_id, primary_key: :uid

  def self.import(payload, repo)
    remote_id = payload.dig(:review, :id)
    raise ArgumentError, 'remote_id required' if remote_id.blank?

    repo.pull_request_reviews.find_or_initialize_by(remote_id: remote_id).tap do |review|
      review.update_attributes(
        remote_pull_request_id: payload.dig(:pull_request, :id),
        state: payload.dig(:review, :state).try(:downcase),
        sha: payload.dig(:pull_request, :head, :sha),
        body: payload.dig(:review, :body),
        url: payload.dig(:review, :html_url),
        reviewer_remote_id: payload.dig(:review, :user, :id),
        reviewer_username: payload.dig(:review, :user, :login),
        remote_created_at: payload.dig(:review, :submitted_at),
        # For debugging purposes whilst developing
        payload: payload
      )
    end
  end
end
