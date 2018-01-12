class Api::BoardTicketsController < Api::BaseController

  load_and_authorize_resource

  def index
    @board_tickets = @board_tickets.includes(:board, :ticket, :swimlane)
    @board_tickets = @board_tickets.where(board_id: params[:board_id]) if params[:board_id].present?
    @board_tickets = @board_tickets.where(tickets: { repo_id: params[:repo_id] }) if params[:repo_id].present?
  end
end
