class TicketCreationService
  attr_reader :board, :title, :repo_id, :description

  def initialize(attributes, board)
    @description = attributes[:description]
    @title = attributes[:title]
    @repo_id = attributes[:repo_id]
    @board = board
  end

  def create_ticket!
    Ticket.transaction do
      ticket = repo.tickets.new(remote_title: title, remote_body: description)
      ticket.save!
      remote_ticket = create_remote_ticket
      ticket.update!(
        remote_id: remote_ticket[:id],
        remote_number: remote_ticket[:number],
        remote_state: remote_ticket[:state]
      )
      board.board_tickets.create!(ticket: ticket, swimlane: board.swimlanes.first)
    end
  end

  private

  def board_repo
    BoardRepo.find(@repo_id)
  end

  def repo
    board_repo.repo
  end

  def create_remote_ticket
    Octokit.create_issue(repo.remote_url, title, description)
  end
end
