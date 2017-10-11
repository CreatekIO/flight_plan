class TicketsController < ApplicationController
  load_and_authorize_resource :board

  def show
    @ticket = Ticket.find(params[:id])
  end

  def update
    board_ticket.update(swimlane_id: params[:ticket][:swimlane_id])
    redirect_to root_path
  end

  def board_ticket
    @ticket.board_tickets.find_by(board: @board)
  end

  private

  def ticket_params
    params.require(:ticket).permit(:swimlane_id)
  end
end
