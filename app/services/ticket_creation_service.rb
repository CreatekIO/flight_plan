class TicketCreationService
  def initialize(attributes)
    @description = attributes[:description]
    @title = attributes[:title]
    @repo_id = attributes[:repo_id]
  end

  def create_ticket
    Ticket.transaction do
      ticket = repo.tickets.new(remote_title: @title, remote_body: @description)
      ticket.save!
      remote_ticket = create_remote_ticket
      ticket.update(remote_id: remote_ticket[:remote_id])
      ticket
    end

  rescue ActiveRecord::RecordInvalid
    false
  end 

  private

  def repo
    Repo.find(@repo_id)
  end

  def create_remote_ticket
    Octokit.create_issue(repo.remote_url, @title, @description)
  end
end
