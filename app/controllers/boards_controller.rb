class BoardsController < AuthenticatedController
  skip_load_and_authorize_resource

  def show
    @hide_container = true
    # TODO: this needs to come from the logged in user
    @boards = Board.all
    @board = Board.find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        @swimlanes = @board.swimlanes.ordered.includes(
          board_tickets: [
            :open_timesheet,
            ticket: [
              :repo,
              pull_requests: %i[repo]
            ]
          ]
        )
      end
    end
  end

  def index
    redirect_to Board.first
  end
end
