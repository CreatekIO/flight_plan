class Api::ReleasesController < Api::BaseController

  load_and_authorize_resource :board

  def create
    @release = @board.releases.create!(release_params)
    @release.create_github_release(create_repo_ids)
    render :show, status: :created
  end

  private

  def release_params
    params.require(:release).permit(:title)
  end

  def create_repo_ids
    params[:release].fetch(:repo_ids, @board.repo_ids)
  end
end

