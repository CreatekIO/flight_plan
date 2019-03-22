class BoardTicketsController < AuthenticatedController
  load_and_authorize_resource :swimlane, only: :index

  load_and_authorize_resource :board, only: :show
  load_and_authorize_resource through: :board, only: :show

  def index
    @board = @swimlane.board
    @board_tickets = @swimlane.preloaded_board_tickets(page: current_page)
    respond_to :json
  end

  def show
    respond_to :json
  end
end
