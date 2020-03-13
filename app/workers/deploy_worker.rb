class DeployWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(board_id)
    board = Board.find board_id
    board.repos.auto_deployable.each do |repo|
      manager = ReleaseManager.new(board, repo)
      next if manager.open_pr?

      manager.create_release
    end
  end
end
