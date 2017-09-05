class BoardsController < ApplicationController
  def show
    @swimlanes = Swimlane.all
  end
end
