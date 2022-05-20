class AssigneesController < AuthenticatedController
  load_and_authorize_resource :repo

  def index
    render json: remote_assignees

    response.headers['Cache-Control'] = @repo.octokit.last_response.headers[:cache_control]
  end

  private

  def octokit_client_options
    { access_token: current_user_github_token.for(@repo) }
  end

  def remote_assignees
    @repo.remote_assignees.map do |user|
      { remote_id: user.id, username: user.login }
    end
  end
end
