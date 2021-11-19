class CycleTimeCalculator
  delegate :id, to: :start_swimlane, prefix: true
  delegate :id, to: :end_swimlane, prefix: true
  delegate :mean, :standard_deviation, :percentile, to: :stats

  class Result
    include Comparable

    SECONDS_IN_WORK_DAY = BusinessTime::Config.end_of_workday - BusinessTime::Config.beginning_of_workday

    attr_reader :title, :number, :slug, :repo_name, :started_at, :ended_at

    def initialize(attributes)
      @title, @number, @slug, @repo_name = attributes.values_at('title', 'number', 'slug', 'repo_name')
      @started_at = attributes['started_at'].in_time_zone
      @ended_at = attributes['ended_at'].in_time_zone
    end

    def duration
      @duration ||= started_at.business_time_until(ended_at) / SECONDS_IN_WORK_DAY
    end

    def github_url
      @github_url ||= format(Ticket::URL_TEMPLATE, repo: slug, number: number)
    end

    def <=>(other)
      raise ArgumentError, "can't compare #{inspect} with #{other.inspect}" unless other.is_a?(self.class)

      [-duration, started_at, ended_at] <=> [-other.duration, other.started_at, other.ended_at]
    end
  end

  def initialize(board, quarter: Quarter.current, start_swimlane_id: nil, end_swimlane_id: nil)
    @board = board
    @quarter = quarter
    @start_swimlane = find_swimlane(id: start_swimlane_id, fallback: 'Development')
    @end_swimlane = find_swimlane(id: end_swimlane_id, fallback: 'Deploying')
  end

  def results
    @results ||= ActiveRecord::Base.connection_pool.with_connection do |conn|
      conn.select_all(query).map { |row| Result.new(row) }.sort!
    end
  end

  def stats
    @stats ||= DescriptiveStatistics::Stats.new(results.map(&:duration))
  end

  private

  attr_reader :board, :quarter, :start_swimlane, :end_swimlane

  def find_swimlane(id:, fallback:)
    if id.present?
      board.swimlanes.find(id)
    else
      board.swimlanes.find_by!(name: fallback)
    end
  end

  def query
    BoardTicket
      .joins(ticket: :repo)
      .arel
      .join(starts).on(SQLHelper.true)
      .join(ends).on(SQLHelper.true)
      .project(
        Ticket.arel_table[:title].as('title'),
        Ticket.arel_table[:number].as('number'),
        Repo.arel_table[:slug].as('slug'),
        Repo.arel_table[:name].as('repo_name'),
        starts.expr[:started_at].as('started_at'),
        ends.expr[:ended_at].as('ended_at')
      )
  end

  def board_tickets
    @board_tickets ||= BoardTicket.arel_table
  end

  def timesheets
    @timesheets ||= Timesheet.arel_table
  end

  def starts
    @starts ||= timesheets
      .project(timesheets[:started_at])
      .where(timesheets[:swimlane_id].eq(start_swimlane_id))
      .where(timesheets[:board_ticket_id].eq(board_tickets[:id]))
      .order(timesheets[:started_at].asc)
      .take(1)
      .lateral('starts')
  end

  def ends
    @ends ||= timesheets
      .project(timesheets[:ended_at])
      .where(timesheets[:after_swimlane_id].eq(end_swimlane_id))
      .where(timesheets[:board_ticket_id].eq(board_tickets[:id]))
      .where(timesheets[:ended_at].between(quarter.as_time_range))
      .order(timesheets[:ended_at].desc)
      .take(1)
      .lateral('ends')
  end
end
