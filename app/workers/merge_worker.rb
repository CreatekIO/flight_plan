class MergeWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(board_id)
    board = Board.find board_id
    board.repos.each do |repo|
      manager = ReleaseManager.new(board, repo)
      next unless manager.open_pr?

      manager.merge_prs
    end
  end
end
