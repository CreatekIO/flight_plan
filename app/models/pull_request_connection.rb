class PullRequestConnection < ApplicationRecord
  belongs_to :ticket, inverse_of: :pull_request_connections
  belongs_to :pull_request, inverse_of: :pull_request_connections
end
