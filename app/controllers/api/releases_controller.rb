class Api::ReleasesController < Api::BaseController

  load_and_authorize_resource :board

  def create
    @release = @board.releases.create!(release_params)
    @release.create_github_release
    render :show, status: :created
  end

  private

  def release_params
    params.require(:release).permit(:title)
  end
end

