class TicketCreationService
  include OctokitClient

  attr_reader :board, :title, :repo_id, :description, :swimlane
  delegate :remote_url, to: :repo, prefix: true

  octokit_methods :create_issue, prefix_with: %i[repo_remote_url]

  def initialize(attributes)
    @description = attributes[:description]
    @title = attributes[:title]
    @swimlane = attributes[:swimlane]
    @repo_id = attributes[:repo_id]
    @board = board_repo.board

    self.octokit_token = attributes[:octokit_token]
  end

  def create_ticket!
    Ticket.transaction do
      remote_ticket = create_remote_ticket
      Ticket.import(remote_ticket, full_name: repo_remote_url)
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
    create_issue(title, description, labels: [ initial_label_name ])
  end

  def initial_label_name
    "status: #{swimlane}"
  end
end
