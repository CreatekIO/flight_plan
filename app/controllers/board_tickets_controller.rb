class BoardTicketsController < AuthenticatedController
  load_and_authorize_resource :swimlane, only: :index

  load_and_authorize_resource :board, only: %i[show create]
  load_and_authorize_resource through: :board, only: :show

  def index
    @board = @swimlane.board
    @board_tickets = @swimlane.preloaded_board_tickets(after: current_cursor)
    respond_to :json
  end

  def create
    @board_ticket = TicketCreationService.new(ticket_params).create_ticket!
    @board = @board_ticket.board
    render :create, status: :created
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def show
    respond_to :json
  end

  private

  def ticket_params
    params.require(:ticket).permit(:title, :description, :repo_id)
  end

  def current_cursor
    params.require(:after)
  end
end
