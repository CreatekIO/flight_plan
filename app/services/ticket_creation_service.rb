class TicketCreationService
  include OctokitClient

  attr_reader :board, :title, :repo_id, :description, :swimlane

  octokit_methods :create_issue, prefix_with: %w[repo.slug]

  def initialize(attributes)
    @description = attributes[:description]
    @title = attributes[:title]
    @swimlane = attributes[:swimlane]
    @repo_id = attributes[:repo_id]
    @board = board_repo.board

    @octokit_token = attributes[:octokit_token]
  end

  def create_ticket!
    Ticket.transaction do
      remote_ticket = create_remote_ticket
      Ticket.import(remote_ticket.to_hash, repo)
    end
  end

  private

  def octokit_client_options
    { access_token: @octokit_token }
  end

  def board_repo
    BoardRepo.find(repo_id)
  end

  def repo
    board_repo.repo
  end

  def create_remote_ticket
    octokit_create_issue(title, description, labels: [ initial_label_name ])
  end

  def initial_label_name
    "status: #{swimlane}"
  end
end
