class FeaturesController < AuthenticatedController
  before_action :check_self_serve_enabled
  before_action :assign_feature

  def create
    authorize! :opt_in, @feature
    @feature.enable_actor(current_user)

    redirect_back fallback_location: boards_path
  end

  def destroy
    authorize! :opt_out, @feature
    @feature.disable_actor(current_user)

    redirect_back fallback_location: boards_path
  end

  private

  def check_self_serve_enabled
    return if Flipper.enabled?(:self_serve_features, current_user)

    render file: 'public/404.html', status: :not_found, layout: false
  end

  def assign_feature
    @feature = Flipper.feature(params[:name])
  end
end
