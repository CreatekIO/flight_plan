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
    ticket = TicketCreationService.new(
      ticket_params.merge(octokit_token: current_user_github_token)
    ).create_ticket!
    @board_ticket = ticket.board_tickets.find_by(board: @board)
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
