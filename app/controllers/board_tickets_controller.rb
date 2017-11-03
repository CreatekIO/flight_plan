class BoardTicketsController < AuthenticatedController
  load_and_authorize_resource :board

  def show
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
