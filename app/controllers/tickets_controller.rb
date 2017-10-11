class TicketsController < ApplicationController
  load_and_authorize_resource :board

  def show
    @ticket = Ticket.find(params[:id])
  end

  def update
    ticket = Ticket.find(params[:id])
    ticket.update_attributes(ticket_params)
    redirect_to root_path
  end

  private

  def ticket_params
    params.require(:ticket).permit(:state)
  end
end
