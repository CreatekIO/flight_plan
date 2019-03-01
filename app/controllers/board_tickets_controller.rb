class BoardTicketsController < AuthenticatedController
  load_and_authorize_resource :board, only: %i[show update]
  load_and_authorize_resource :swimlane, only: :index

  def index
    @board = @swimlane.board
    @board_tickets = @swimlane.preloaded_board_tickets(page: current_page)
    respond_to :json
  end

  def show
    respond_to :json
  end

  def update
    @board_ticket.update(board_ticket_params)
    redirect_to board_path(@board)
  end

  private

  def board_ticket_params
    params.require(:board_ticket).permit(:swimlane_id)
  end
end
