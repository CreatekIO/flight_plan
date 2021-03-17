class BoardsController < AuthenticatedController
  layout 'application_v2'

  def show
    @hide_container = true
    # TODO: this needs to come from the logged in user
    @boards = Board.all
    @board = Board.find(params[:id])

    respond_to :html, :json
  end

  def index
    redirect_to Board.first
  end
end
