class Quarter
  FORMAT = '%Y-%m'.freeze

  def self.current
    new(Time.now.utc)
  end

  def self.calculate_sql(column)
    Arel::Nodes::NamedFunction.new(
      'DATE_FORMAT',
      [column, Arel.sql("'#{FORMAT}'")]
    )
  end

  attr_reader :reference_time

  def initialize(reference_time)
    @reference_time = reference_time
  end

  def months
    start = as_date_range.begin

    Array.new(3) { |n| (start + n.months).strftime(FORMAT) }
  end

  def as_time_range
    @as_time_range ||= reference_time.all_quarter
  end

  def as_date_range
    @as_date_range ||= reference_time.to_date.all_quarter
  end
end
