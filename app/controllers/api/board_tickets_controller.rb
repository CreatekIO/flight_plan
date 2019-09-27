class Api::BoardTicketsController < AuthenticatedController
  load_and_authorize_resource

  def index
    @board_tickets = @board_tickets.includes(:board, :ticket, :swimlane)
    @board_tickets = @board_tickets.for_board(params[:board_id]) if params[:board_id].present?
    @board_tickets = @board_tickets.for_repo(params[:repo_id]) if params[:repo_id].present?
    @board_tickets = @board_tickets.where(tickets: { remote_number: params[:remote_number] }) if params[:remote_number].present?
  end

  private

  def ticket_params
    params.require(:ticket).permit(:title, :description, :repo_id)
  end
end
