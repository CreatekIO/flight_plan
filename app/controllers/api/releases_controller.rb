class Api::ReleasesController < Api::BaseController
  load_and_authorize_resource :board

  before_action :check_deploy_swimlane, only: :create

  def create
    @release = @board.releases.create!(release_params)
    @release.create_github_release(params[:release][:repo_ids])
    render :show, status: :created
  end

  private

  def release_params
    params.require(:release).permit(:title)
  end

  def check_deploy_swimlane
    return if @board.deploy_swimlane.present?

    render_error('A deploy swimlane has not been configured for this board')
  end
end

