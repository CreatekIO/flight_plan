class IdeasController < ApplicationController
  layout 'hotwire'

  def index
    @ideas = Idea.all
  end
end
