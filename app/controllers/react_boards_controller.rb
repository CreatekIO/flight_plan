class ReactBoardsController < AuthenticatedController

  skip_load_and_authorize_resource

  def show
    @hide_container = true
    # todo: this needs to come from the logged in user
    @boards = Board.all
    @board = Board.find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        @swimlanes = @board.swimlanes.ordered.includes(
          board_tickets: {
            ticket: %i[repo pull_requests]
          }
        )
      end
    end
  end

  def index
    redirect_to @boards.first
  end
end
