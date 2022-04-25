class BoardTicketsController < AuthenticatedController
  load_and_authorize_resource :swimlane, only: :index

  load_and_authorize_resource :board, only: %i[show create]
  before_action :assign_board_ticket, only: :show

  def index
    @board = @swimlane.board
    @board_tickets = @swimlane.preloaded_board_tickets(after: current_cursor)
    respond_to :json
  end

  def create
    repo = @board.board_repos.find(ticket_params[:repo_id]).repo
    ticket = TicketCreationService.new(
      ticket_params.merge(octokit_token: current_user_github_token.for(repo))
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

  def assign_board_ticket
    scope = @board.board_tickets

    @board_ticket = if params[:slug]
      scope.joins(ticket: :repo).merge(
        Ticket.with_slug_and_number(params[:slug], params[:number])
      ).first!
    else
      scope.find(params[:id])
    end

    authorize! action_name, @board_ticket
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :repo_id, :swimlane)
  end

  def current_cursor
    params.require(:after)
  end
end
