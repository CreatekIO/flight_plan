class PullRequestReview < ApplicationRecord
  belongs_to :repo
  belongs_to :pull_request, foreign_key: :remote_pull_request_id, primary_key: :remote_id
  belongs_to :reviewer, -> { where(provider: 'github') }, class_name: 'User',
    foreign_key: :reviewer_remote_id, primary_key: :uid
end
