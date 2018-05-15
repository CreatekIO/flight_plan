class Release < ApplicationRecord
  belongs_to :board
  has_many :release_board_tickets, dependent: :destroy
  has_many :repo_releases, dependent: :destroy
  has_many :board_tickets, through: :release_board_tickets
end
