class TicketMovesController < AuthenticatedController
  load_and_authorize_resource :board
  load_and_authorize_resource :board_ticket, through: :board, id_param: :ticket_id

  def create
    if @board_ticket.update(board_ticket_params)
      broadcast_update
      render :create, status: :created
    else
      render json: { errors: @board_ticket.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def board_ticket_params
    params
      .require(:board_ticket)
      .permit(:swimlane_id, :swimlane_position)
      .merge(octokit_token: current_user_github_token.for(@board_ticket.repo))
  end

  def create_params
  end

  def broadcast_update
    BoardChannel.broadcast_to(
      @board,
      redux_action(:TICKET_WAS_MOVED) do |json|
        json.boardTicket do
          json.partial! @board_ticket, swimlane: @board_ticket.swimlane
        end
        json.destinationId @board_ticket.swimlane_id
        json.destinationIndex board_ticket_params[:swimlane_position].to_i
      end
    )
  end

  def redux_action(type)
    JbuilderTemplate.new(view_context) do |json|
      json.type "ws/#{type}"
      json.payload { yield(json) }
      json.meta { json.userId(current_user.id) }
    end.attributes!
  end
end
