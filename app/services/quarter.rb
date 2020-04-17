class Quarter
  FORMAT = '%Y-%m'.freeze
  UTC = Time.find_zone!('UTC')

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
    Arel::Nodes::NamedFunction.new(
      'DATE_FORMAT',
      [column, Arel.sql("'#{FORMAT}'")]
    )
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
    "#{start.strftime('%b')} - #{finish.strftime('%b %Y')}"
  end
end
