class Release < ApplicationRecord
  belongs_to :board
  belongs_to :repo
  has_many :release_board_tickets, dependent: :destroy
  has_many :board_tickets, through: :release_board_tickets
end
