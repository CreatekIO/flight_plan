class DeployWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(board_id)
    board = Board.find(board_id)

    logger.info("Checking deploys for Board##{board.id} '#{board.name}'")

    board.repos.auto_deployable.each do |repo|
      logger.info("Checking Repo##{repo.id} (#{repo.slug})")

      manager = ReleaseManager.new(board, repo)
      if manager.open_pr?
        logger.info("Repo##{repo.id} (#{repo.slug}) has open release PR, skipping")
        next
      end

      logger.info("Creating release for Repo##{repo.id} (#{repo.slug})")
      manager.create_release
    end
  end
end
