class TicketCreationService
  attr_reader :board, :title, :repo_id, :description

  def initialize(attributes)
    @description = attributes[:description]
    @title = attributes[:title]
    @repo_id = attributes[:repo_id]
    @board = board_repo.board
  end

  def create_ticket!
    Ticket.transaction do
      remote_ticket = create_remote_ticket
      Ticket.import(remote_ticket, full_name: repo.remote_url)
    end
  end

  private

  def board_repo
    BoardRepo.find(repo_id)
  end

  def repo
    board_repo.repo
  end

  def create_remote_ticket
    Octokit.create_issue(repo.remote_url, title, description)
  end
end
