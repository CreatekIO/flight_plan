class BoardsController < ApplicationController
  def show
    # todo: this needs to come from the logged in user
    @boards = Board.all
  end

  def index
    redirect_to @boards.first
  end
end
