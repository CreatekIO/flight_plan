class PullRequestDashboardsController < AuthenticatedController
  load_and_authorize_resource :board
  skip_load_and_authorize_resource

  def index
    @repos = @board.repos.includes(open_pull_requests: :reviews)
  end
end
