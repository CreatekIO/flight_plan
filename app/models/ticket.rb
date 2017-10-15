class Ticket < ApplicationRecord
  belongs_to :repo

  has_many :comments, dependent: :destroy
  has_many :board_tickets, dependent: :destroy

  def self.import_from_remote(issue, repo)
    ticket = find_by_remote(issue, repo)
    ticket.update_attributes(
      remote_number: issue[:number],
      remote_title: issue[:title],
      remote_body: issue[:body],
      remote_state: issue[:state],
    )

    ticket.update_board_tickets_from_remote(issue)
    ticket
  end

  def self.find_by_remote(issue, repo)
    ticket = Ticket.find_or_initialize_by(remote_id: issue[:id])
    if ticket.repo_id.blank?
      ticket.repo = Repo.find_by(remote_url: repo[:full_name]) 
    end
    ticket
  end

  def update_board_tickets_from_remote(issue)
    repo.boards.each do |board|
      bt = board_tickets.find_or_initialize_by(board: board)
      bt.update_remote = false
      bt.swimlane = swimlane_from_remote(issue, board)
      bt.save
    end
  end

  private

  def swimlane_from_remote(issue, board)
    if issue['state'] == 'closed'
      return board.closed_swimlane
    else
      status_label = issue[:labels].find do |label|
        label[:name].starts_with? 'status:'
      end

      if status_label
        return board.swimlanes.find_by_label!(status_label[:name])
      else
        return board.open_swimlane
      end
    end
  end

end
