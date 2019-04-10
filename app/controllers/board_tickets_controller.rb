class BoardTicketsController < AuthenticatedController
  load_and_authorize_resource :swimlane, only: :index

  load_and_authorize_resource :board, only: :show
  load_and_authorize_resource through: :board, only: :show

  def index
    @board = @swimlane.board
    @board_tickets = @swimlane.preloaded_board_tickets(after: current_cursor)
    respond_to :json
  end

  def show
    respond_to :json
  end

  private

  def current_cursor
    params.require(:after)
  end
end
