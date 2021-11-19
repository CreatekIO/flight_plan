require 'csv'

class CumulativeFlowCalculator
  include SQLHelper

  GROUPINGS = {
    in_progress: %w[Development],
    demo: %w[Demo],
    code_review: ['Demo - DONE', 'Code Review', 'Code Review - DONE'],
    acceptance: %w[Acceptance],
    done: ['Acceptance - DONE', 'Deploying', 'Deploying - DONE']
  }.freeze

  REVERSE_GROUPINGS = GROUPINGS.each_with_object({}) do |(type, names), mapping|
    names.each { |name| mapping[name] = type }
  end.freeze

  def initialize(board, start:, finish:)
    @board = board
    @start = start
    @finish = finish

    @timesheets = Timesheet.arel_table
    @dates = table('dates')
  end

  def results
    @results ||= ActiveRecord::Base.connection_pool.with_connection do |conn|
      conn.select_all(query)
    end
  end

  def to_csv
    CSV.generate do |csv|
      csv << results.columns.map(&:titleize)
      results.rows.each { |row| csv << row }
    end
  end

  private

  attr_reader :board, :start, :finish, :timesheets, :dates

  def query
    # Handle "done" separately since we want to normalise values
    # against the first value in the list, and that means having
    # to join against the subquery in order to window against it
    counts = grouped_swimlanes.except(:done).map do |(group_name, swimlanes)|
      count_tickets(swimlanes: swimlanes).as(group_name.to_s)
    end

    done = sql.alias(
      sql[:done_raw, :count] - first_value(sql[:done_raw, :count]).over,
      as: 'done'
    )

    select(cast(dates[:date], as: :date), done, *counts.reverse)
      .from(dates_source)
      .join(count_tickets(swimlanes: grouped_swimlanes[:done]).lateral('done_raw')).on(sql.true)
      .where(dates[:date].extract(:isodow).lt(6)) # exclude weekends
      .where(dates[:date].not_in(holidays)) # ...and holidays
  end

  def grouped_swimlanes
    @grouped_swimlanes ||= board.swimlanes
      .group_by { |swimlane| REVERSE_GROUPINGS[swimlane.name] }
      .except(nil) # get rid of ungrouped swimlanes
  end

  def dates_source
    date_series(start, finish).as("#{dates.name}(date)")
  end

  def count_tickets(swimlanes:)
    select(count(1, as: 'count'))
      .from(timesheets)
      .where(timesheets[:swimlane_id].in(swimlanes.map(&:id)))
      .where(timesheets_in_date_range)
  end

  def timesheets_in_date_range
    @timesheets_in_date_range ||= between(
      dates[:date],
      from: timesheets[:started_at],
      to: coalesce(timesheets[:ended_at], infinity)
    )
  end

  def holidays
    (start..finish).select(&:weekday?).reject(&:workday?)
  end
end
