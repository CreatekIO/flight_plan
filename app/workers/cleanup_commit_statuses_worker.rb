class CleanupCommitStatusesWorker
  include Sidekiq::Worker

  RANK_ALIAS = 'rank'.freeze

  def perform
    ranked = CommitStatus.select(:id, :state, ranking).arel.as('ranked')

    ids = CommitStatus
      .from(ranked)
      .where(ranked[RANK_ALIAS].gt(1).and(ranked[:state].eq('pending')))
      .select(ranked[:id])

    deleted_count = CommitStatus.where(id: ids).delete_all
    logger.info "Removed #{deleted_count} statuses, #{CommitStatus.count} remain"
  end

  private

  def ranking
    dense_rank = Arel::Nodes::NamedFunction.new('DENSE_RANK', [])
    table = CommitStatus.arel_table

    partition = Arel::Nodes::Window.new
      .partition(table[:repo_id], table[:sha], table[:context])
      .order(table[:remote_created_at].desc)

    dense_rank.over(partition).as(RANK_ALIAS)
  end
end
