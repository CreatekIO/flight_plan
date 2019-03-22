class PullRequestDashboardsController < AuthenticatedController
  load_and_authorize_resource :board

  def index
    @hide_container = true
    @boards = Board.all
    @repos = @board.repos.includes(open_pull_requests: :reviews)
  end
end
