class Release < ApplicationRecord
  belongs_to :board
  has_many :release_board_tickets, dependent: :destroy
  has_many :repo_releases, dependent: :destroy
  has_many :board_tickets, through: :release_board_tickets

  after_create :create_repo_releases

  private

  def create_repo_releases
    board.repos.each do |repo|
      repo_releases.create(repo: repo)
    end
  end
end
