class RepoReleaseBoardTicket < ApplicationRecord
  belongs_to :release
  belongs_to :board_ticket
end
