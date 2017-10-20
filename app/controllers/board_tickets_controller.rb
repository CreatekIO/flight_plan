class BoardTicketsController < ApplicationController
  load_and_authorize_resource :board
  load_and_authorize_resource

  def show
  end

  def update
    @board_ticket.update(board_ticket_params)
    redirect_to root_path
  end

  private

  def board_ticket_params
    params.require(:board_ticket).permit(:swimlane_id)
  end
end
