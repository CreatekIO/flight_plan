class GithubAssetsController < AuthenticatedController
  before_action :assign_repo

  REDIRECT_STATUSES = [301, 302, 303, 307].freeze

  def show
    return head :not_found unless asset_has_valid_redirect?

    redirect_to asset.headers[:location]
  end

  private

  def assign_repo
    @repo = Repo.find_by_slug!(params[:slug])
  end

  def asset
    @asset ||= Faraday.get("https://github.com/#{params[:slug]}/#{params[:path]}") do |req|
      req.headers[:accept] = '*/*'
      req.headers[:authorization] = "token #{current_user_github_token.for(@repo)}"
    end
  end

  def asset_has_valid_redirect?
    REDIRECT_STATUSES.include?(asset.status) && asset.headers[:location].present?
  end
end
