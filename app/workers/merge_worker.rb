class MergeWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(board_id)
    board = Board.find(board_id)

    logger.info("Checking for releases to merge for Board##{board.id} '#{board.name}'")

    board.repos.auto_deployable.each do |repo|
      logger.info("Checking Repo##{repo.id} (#{repo.slug})")

      manager = ReleaseManager.new(board, repo)
      unless manager.open_pr?
        logger.info("Repo##{repo.id} (#{repo.slug}) has no open release PRs, skipping")
        next
      end

      logger.info("Merging release(s) for Repo##{repo.id} (#{repo.slug})")
      manager.merge_prs
    end
  end
end
