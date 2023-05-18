class IdeasController < ApplicationController
  layout 'hotwire'

  def index
    @pending_ideas = Idea.pending
    @accepted_ideas = Idea.accepted
  end

  def new
    @idea = Idea.new
  end

  def create
    @idea = Idea.new(ideas_params)
    @idea.submitter = current_user
    @created_idea = @idea
    @idea = Idea.new if @idea.save

    respond_to :turbo_stream

  end

  def ideas_params
    params.require(:idea).permit(:title, :description)
  end
end
