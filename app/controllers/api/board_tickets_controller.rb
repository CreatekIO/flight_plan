class Api::BoardTicketsController < AuthenticatedController
  before_action :find_board, only: :create

  load_and_authorize_resource

  def index
    @board_tickets = @board_tickets.includes(:board, :ticket, :swimlane)
    @board_tickets = @board_tickets.for_board(params[:board_id]) if params[:board_id].present?
    @board_tickets = @board_tickets.for_repo(params[:repo_id]) if params[:repo_id].present?
    @board_tickets = @board_tickets.where(tickets: { remote_number: params[:remote_number] }) if params[:remote_number].present?
  end

  def create
    ticket = TicketCreationService.new(ticket_params).create_ticket
    @board.board_tickets.create(ticket: ticket, swimlane: @board.swimlanes.first)
  end

  private

  def find_board
    @board = Board.find(params[:board_id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :repo_id)
  end
end
