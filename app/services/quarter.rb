class Quarter
  FORMAT = '%Y-%m'.freeze
  SQL_FORMAT = 'YYYY-MM'.freeze
  UTC = Time.find_zone!('UTC')
  START_MONTHS = [1, 4, 7, 10].freeze

  def self.current
    from(UTC.now)
  end

  def self.from(date)
    case date
    when /^\d{4}-\d{2}$/
      datetime = UTC.parse(date.tr('-', '/'))
      new(datetime.all_quarter)
    when Date, DateTime, ActiveSupport::TimeWithZone
      new(date.all_quarter)
    end
  end

  def self.calculate_sql(column)
    SQLHelper.to_char(column, SQLHelper.quote(SQL_FORMAT))
  end

  attr_reader :range
  alias_method :as_time_range, :range

  delegate :first, :last, to: :range
  delegate :future?, to: :start

  alias_method :start, :first
  alias_method :finish, :last

  def initialize(range)
    @range = range
  end

  def months
    start_date = start.to_date

    Array.new(3) { |n| (start_date + n.months).strftime(FORMAT) }
  end

  def next
    self.class.new(start.next_quarter.all_quarter)
  end

  def previous
    self.class.new(start.last_quarter.all_quarter)
  end

  def to_param
    start.strftime(FORMAT)
  end

  def to_s
    "Q#{number} #{start.strftime('%b')} - #{finish.strftime('%b %Y')}"
  end

  def number
    START_MONTHS.index(start.month) + 1
  end

  def as_date_range
    first.to_date..last.to_date
  end

  def holidays
    as_date_range.select(&:weekday?).reject(&:workday?)
  end
end
