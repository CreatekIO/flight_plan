class Api::BoardsController < Api::BaseController
  skip_before_action :authenticate_user
  respond_to :json

  def index
    respond_with Board.all
  end
end
