class BugTicketsCalculator
  include Enumerable

  LABELS = ['bug', 'BUG', 'type: bug'].freeze

  Stat = Struct.new(:date, :state, :count) do
    def opened?
      state == 'opened'
    end

    def closed?
      state == 'closed'
    end
  end

  def initialize(board, quarter: Quarter.current)
    @board = board
    @quarter = quarter
  end

  def each
    return enum_for(:each) unless block_given?

    quarter.months.each do |date|
      closed_count = bugs_closed_in_quarter.fetch(date, 0)
      opened_count = bugs_opened_in_quarter.fetch(date, 0)

      yield Stat.new(date, 'closed', closed_count)
      yield Stat.new(date, 'opened', opened_count)
    end
  end

  private

  attr_reader :board, :quarter

  def bug_tickets
    @bug_tickets ||= board.tickets.joins(:labels).where(labels: { name: LABELS })
  end

  def bugs_opened_in_quarter
    @bugs_opened_in_quarter ||= bug_tickets.where(
      remote_created_at: quarter.as_time_range
    ).group(
      Quarter.calculate_sql(Ticket.arel_table[:remote_created_at]).to_sql
    ).count
  end

  def bugs_closed_in_quarter
    @bugs_closed_in_quarter ||= bug_tickets.where(
      remote_closed_at: quarter.as_time_range
    ).group(
      Quarter.calculate_sql(Ticket.arel_table[:remote_closed_at]).to_sql
    ).count
  end
end
