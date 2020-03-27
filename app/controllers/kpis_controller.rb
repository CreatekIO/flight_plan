class KpisController < AuthenticatedController
  def index
    board = Board.find(params[:board_id])
    @cycle_time_results = CycleTimeCalculator.new(board).results
  end
end
