class CycleTimeCalculator
  delegate :joins, :where, to: :BoardTicket

  # Mon-Sun across the top and down the side
  DATE_MATRIX =
    '0 1 2 3 4 4 4' \
    '4 0 1 2 3 3 3' \
    '3 4 0 1 2 2 2' \
    '2 3 4 0 1 1 1' \
    '1 2 3 4 0 0 0' \
    '0 1 2 3 4 0 0' \
    '0 1 2 3 4 4 0'.remove(/\s+/).freeze

  def initialize(board)
    @board = board
    @start_swimlane = board.swimlanes.find_by!(name: 'Development')
    @end_swimlane = board.swimlanes.find_by!(name: 'Deploying')
  end

  def results
    @results ||= ActiveRecord::Base.connection_pool.with_connection do |conn|
      conn.select_all(query.to_sql)
    end
  end

  def stats
    @stats ||= DescriptiveStatistics::Stats.new(results.map { |row| row['cycle_time'] })
  end

  private

  attr_reader :board, :start_swimlane, :end_swimlane

  def query
    BoardTicket
      .joins(ticket: :repo)
      .merge(with_starting_timesheet)
      .merge(with_ending_timesheet)
      .select(
        Ticket.arel_table[:remote_title].as('title'),
        Ticket.arel_table[:remote_number].as('number'),
        Repo.arel_table[:remote_url].as('repo'),
        start_time.as('started_at'),
        end_time.as('ended_at'),
        cycle_time
      ).order(
        Arel.sql('cycle_time').desc,
        start_time.asc,
        end_time.asc
      ).distinct
  end

  def board_tickets
    @board_tickets ||= BoardTicket.arel_table
  end

  def starts
    @starts ||= Timesheet.arel_table.alias('starts')
  end

  def ends
    @ends ||= Timesheet.arel_table.alias('ends')
  end

  def start_time
    @start_time ||= starts[:started_at]
  end

  def end_time
    @end_time ||= ends[:started_at]
  end

  # From https://stackoverflow.com/a/6762805
  # - counts difference in days between start and end,
  #   not counting weekends
  def cycle_time
    quoted_start_time = "`#{start_time.relation.name}`.`#{start_time.name}`"
    quoted_end_time = "`#{end_time.relation.name}`.`#{start_time.name}`"

    difference_in_week_days = Arel.sql(
      "5 * (DATEDIFF(#{quoted_end_time}, #{quoted_start_time}) DIV 7) +" \
      " MID('#{DATE_MATRIX}', 7 * WEEKDAY(#{quoted_start_time}) + WEEKDAY(#{quoted_end_time}) + 1, 1)"
    )

    difference_in_week_days.as('cycle_time')
  end

  def with_starting_timesheet
    previous_start = Timesheet.arel_table.alias('previous_start')

    joins = board_tickets.join(starts).on(
      board_tickets[:id].eq(starts[:board_ticket_id]).and(
        starts[:swimlane_id].eq(start_swimlane.id)
      )
    ).outer_join(previous_start).on(
      starts[:swimlane_id].eq(previous_start[:swimlane_id]).and(
        starts[:board_ticket_id].eq(previous_start[:board_ticket_id])
      ).and(
        previous_start[:started_at].lt(starts[:started_at])
      )
    )

    joins(joins.join_sources).where(previous_start[:id].eq(nil))
  end

  def with_ending_timesheet
    next_end = Timesheet.arel_table.alias('next_end')

    joins = board_tickets.join(ends).on(
      board_tickets[:id].eq(ends[:board_ticket_id]).and(
        ends[:swimlane_id].eq(end_swimlane.id)
      )
    ).outer_join(next_end).on(
      ends[:swimlane_id].eq(next_end[:swimlane_id]).and(
        ends[:board_ticket_id].eq(next_end[:board_ticket_id])
      ).and(
        next_end[:started_at].gt(ends[:started_at])
      )
    )

    joins(joins.join_sources).where(next_end[:id].eq(nil))
  end
end
