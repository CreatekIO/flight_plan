class KpisController < AuthenticatedController
  def index
    board = Board.find(params[:board_id])
    @cycle_time = CycleTimeCalculator.new(board)
  end
end
