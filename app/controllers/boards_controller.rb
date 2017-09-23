class BoardsController < ApplicationController
  def show
  end

  def index
    redirect_to @boards.first
  end
end
