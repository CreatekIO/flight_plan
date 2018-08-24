class RepoReleaseBoardTicket < ApplicationRecord
  belongs_to :repo_release
  belongs_to :board_ticket
end
