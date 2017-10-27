class AutoDeploy

  #TODO: write tests

  DEPLOY_DELAY = 10.minutes

  def initialize(board)
    @board = board
  end

  def self.deploy_all
    Board.where(auto_deploy: true).where(['next_deployment <= ?', Time.now]).each do |board|
      DeployWorker.perform_async(board.id)
    end
  end

  def schedule_next_deployment
    if pending_auto_deployment?
      board.update_attributes(next_deployment: calculate_next_deployment)
    end
  end

  def deploy
    log "Deploying board #{board.name}"
    board.repos.each do |repo|
      tickets = board.deploy_swimlane.tickets.where(repo_id: repo.id)
      if tickets.any?
        relsr = Relsr.new(
          repo_name: repo.remote_url,
          tickets: tickets,
          extra_branches: []
        )
        relsr.create_release_branch
        relsr.create_pull_request
        board.update(next_deployment: nil)
      end
    end
  end

  private

  def log(message)
  end

  attr_reader :board

  def pending_auto_deployment?
    board.auto_deploy? && board.deploy_swimlane.board_tickets.any? 
  end

  def calculate_next_deployment
    last_ticket = board.deploy_swimlane.board_tickets.order(:updated_at).last

    deploy_at = last_ticket.updated_at + DEPLOY_DELAY

    if deploy_at < '9am'
      deploy_at = deploy_at.change(hour: 9, minute: 0, second: 0)
    elsif deploy_at > '5pm'
      deploy_at = deploy_at.change(hour: 9, minute: 0, second: 0)
      deploy_at += 1.day
    end

    loop do
      break if (1..5).include? deploy_at.wday
      deploy_at += 1.day
    end

    deploy_at
  end

end
