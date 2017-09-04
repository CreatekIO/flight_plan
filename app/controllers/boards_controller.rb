class BoardsController < ApplicationController
  def show
    @swimlanes = WORKFLOW[:swimlanes]
  end
end
