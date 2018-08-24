class PullRequestConnection < ApplicationRecord
  belongs_to :ticket
  belongs_to :pull_request
end
