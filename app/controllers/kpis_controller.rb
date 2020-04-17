class KpisController < AuthenticatedController
  def index
    authorize! :index, :kpis
    @board = Board.find(params[:board_id])

    @quarter = derive_quarter_from(params[:date])
    @bug_tickets = BugTicketsCalculator.new(@board, quarter: @quarter)
    @circleci_builds = CircleciBuildsCalculator.new(@board, quarter: @quarter)
    @cycle_time = CycleTimeCalculator.new(@board)
  end

  private

  def derive_quarter_from(date)
    return Quarter.current if date.blank?

    Quarter.from(date)
  end
end
