class Ticket < ApplicationRecord
  belongs_to :repo

  has_many :comments, dependent: :destroy
  has_many :board_tickets, dependent: :destroy

  def self.import_from_remote(issue, repo)
    ticket = Ticket.find_or_initialize_by(remote_id: issue[:id])
    if ticket.repo_id.blank?
      ticket.repo = Repo.find_by(remote_url: repo[:full_name]) 
    end
    ticket.update_attributes(
      remote_number: issue[:number],
      remote_title: issue[:title],
      remote_body: issue[:body],
      remote_state: issue[:state],
    )

    ticket.repo.boards.each do |board|
      BoardTicket.find_or_create_by(
        ticket: ticket, 
        board: board,
      ) do |bt|
        bt.swimlane = board.open_swimlane 
      end
    end
  end
end
