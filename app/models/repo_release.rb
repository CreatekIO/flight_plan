class RepoRelease < ApplicationRecord
  belongs_to :repo
  belongs_to :release
  has_one :board, through: :release

  has_many :repo_release_board_tickets, dependent: :destroy
  has_many :board_tickets, through: :repo_release_board_tickets

  after_create :create_release

  private

  def create_release
    self.status = 'void'
    manager = ReleaseManager.new(board, repo)
    manager.create_release
    manager.unmerged_tickets.each do |ticket|
      board_tickets << board.board_tickets.find_by(ticket: ticket)
    end
  end
end
