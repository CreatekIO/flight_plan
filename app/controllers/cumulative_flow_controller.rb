class CumulativeFlowController < AuthenticatedController
  load_and_authorize_resource :board

  def show
    authorize! :index, :kpis

    @from, @to = dates_from_range.presence || dates_from_params
    @calculator = CumulativeFlowCalculator.new(@board, start: @from, finish: @to)

    respond_to do |format|
      format.html
      format.csv { send_data @calculator.to_csv, type: Mime[:csv] }
    end
  end

  private

  def dates_from_range
    case params[:range]
    when /^(\d)-weeks?$/
      [Date.today - Integer(Regexp.last_match(1)).weeks, Date.today]
    when 'quarter'
      range = Quarter.current.as_date_range
      [range.begin, [range.end, Date.today].min]
    else
      nil
    end
  end

  def dates_from_params
    [
      parse_date(params[:from]) { Date.today - 2.weeks },
      parse_date(params[:to]) { Date.today }
    ].sort
  end

  def parse_date(value)
    return yield if value.blank?

    date = Date.parse(value)
    date.future? ? yield : date
  rescue ArgumentError, RangeError
    yield
  end
end
