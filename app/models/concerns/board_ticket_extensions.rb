module BoardTicketExtensions
  def by_swimlane(page: 1, per: 1000)
    start_rank = (page - 1) * per
    end_rank = start_rank + per - 1

    eager_load(:swimlane)
      .partition_by(:swimlane_id, order_by: :swimlane_sequence)
      .order(Swimlane.arel_table[:position].asc, partition_rank.asc)
      .having(partition_rank.between(start_rank..end_rank))
  end

  def count(column_name = :id)
    if by_swimlane?
      super.size
    else
      super
    end
  end

  protected

  def partition_by(column_name, order_by:)
    self_join = arel_table.outer_join(self_join_alias).on(
      arel_table[column_name].eq(self_join_alias[column_name]).and(
        self_join_alias[order_by].lt(arel_table[order_by])
      )
    )

    select(self_join_alias[:id].count.as(partition_rank))
      .joins(self_join.join_sources)
      .group(:id)
  end

  private

  def partition_rank
    @partition_rank ||= Arel.sql('partition_rank')
  end

  def self_join_alias
    @self_join_alias ||= arel_table.alias
  end

  def by_swimlane?
    arel.projections.any? { |projection| projection.try(:alias) == partition_rank.to_s }
  end
end
