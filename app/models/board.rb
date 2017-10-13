class Board < ApplicationRecord
  has_many :board_repos, dependent: :destroy
  has_many :repos, through: :board_repos
  has_many :swimlanes, dependent: :destroy
  has_many :board_tickets, dependent: :destroy

  def open_swimlane
    swimlanes.order(:position).first
  end

  def closed_swimlane
    # TODO: need to signify which column is the closed column on a board via config (not hard coded)
    swimlanes.order(:position).last
  end
end
