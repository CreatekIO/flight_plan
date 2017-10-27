class DeployWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(board_id)
    AutoDeploy.new(Board.find(board_id)).deploy
  end
end
