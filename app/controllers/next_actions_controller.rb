class NextActionsController < AuthenticatedController
  skip_load_and_authorize_resource

  def index
    @repos = Board.find(params[:board_id]).repos

    respond_to :json
  end
end
