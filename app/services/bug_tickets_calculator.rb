class BugTicketsCalculator
  include Enumerable

  LABELS = ['bug', 'BUG', 'type: bug'].freeze

  Stat = Struct.new(:date, :state, :count) do
    def open?
      state == 'open'
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
      %w[closed open].each do |state|
        count = bugs_created_in_quarter.fetch([date, state], 0)

        yield Stat.new(date, state, count)
      end
    end
  end

  private

  attr_reader :board, :quarter

  def bugs_created_in_quarter
    @bugs_created_in_quarter ||= board.tickets.joins(:labels).where(
      remote_created_at: quarter.as_time_range,
      labels: { name: LABELS }
    ).group(year_and_month.to_sql, :remote_state).count
  end

  def year_and_month
    Quarter.calculate_sql(Ticket.arel_table[:remote_created_at])
  end
end
