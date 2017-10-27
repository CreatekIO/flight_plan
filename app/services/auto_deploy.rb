class AutoDeploy

  def initialize(board)
    @board = board
  end

  def self.deploy_all
    Board.where(auto_deploy: true).where(['next_deployment <= ?', Time.now]).each do |board|
      AutoDeploy.new(board).deploy
    end
  end

  def deploy
    puts "Deploying board #{board.name}"
    board.deploy_swimlane.tickets.each do |ticket|
      puts "  - #{ticket.remote_title}"
    end
  end

  private

  attr_reader :board
end
