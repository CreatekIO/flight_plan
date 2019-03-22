class TicketMovesController < AuthenticatedController
  load_and_authorize_resource :board
  load_and_authorize_resource :board_ticket, through: :board, id_param: :ticket_id

  def create
    if @board_ticket.update_attributes(board_ticket_params)
      render :create, status: :created
    else
      render json: { errors: @board_ticket.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def board_ticket_params
    params.require(:board_ticket).permit(:swimlane_id, :swimlane_position)
  end
end
