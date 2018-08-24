class Release < ApplicationRecord
  belongs_to :board
  has_many :repos, through: :board
  has_many :release_board_tickets, dependent: :destroy
  has_many :repo_releases, dependent: :destroy
  has_many :board_tickets, through: :release_board_tickets

  def create_github_release(repo_ids = nil)
    repo_ids ||= board.repo_ids
    repos.where(id: repo_ids).each do |repo|
      repo_releases.create!(repo: repo).create_github_release
    end
  end
end
