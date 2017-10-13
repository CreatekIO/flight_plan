class BoardTicketsController < ApplicationController
  load_and_authorize_resource :board

  def show
  end

  def update
    @board_ticket.update(swimlane_id: params[:ticket][:swimlane_id])
    redirect_to root_path
  end
end
