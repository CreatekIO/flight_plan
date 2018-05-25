class PullRequestReview < ApplicationRecord
  belongs_to :repo
  belongs_to :pull_request, foreign_key: :remote_pull_request_id, primary_key: :remote_id
end
