class NextActionsController < AuthenticatedController
  def index
    @repos = Board.find(params[:board_id]).repos

    respond_to :json
  end
end
