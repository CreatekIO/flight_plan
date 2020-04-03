class KpisController < AuthenticatedController
  def index
    board = Board.find(params[:board_id])

    @bug_tickets = BugTicketsCalculator.new(board)
    @cycle_time = CycleTimeCalculator.new(board)
    @circleci_builds = CircleciBuildsCalculator.new(board)
  end
end
