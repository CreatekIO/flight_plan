class TicketMovesController < AuthenticatedController
  load_and_authorize_resource :board
  load_and_authorize_resource :board_ticket, through: :board, id_param: :ticket_id

  def create
    if @board_ticket.update_attributes(board_ticket_params.merge(octokit_token: current_user_github_token))
      broadcast_update
      render :create, status: :created
    else
      render json: { errors: @board_ticket.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def board_ticket_params
    params.require(:board_ticket).permit(:swimlane_id, :swimlane_position)
  end

  def broadcast_update
    BoardChannel.broadcast_to(
      @board,
      type: 'TICKET_WAS_MOVED',
      payload: {
        userId: current_user.id,
        boardTicket: render_to_string(:create, formats: :json),
        destinationId: @board_ticket.swimlane_id,
        destinationIndex: board_ticket_params[:swimlane_position].to_i
      }
    )
  end
end
