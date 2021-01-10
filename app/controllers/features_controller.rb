class FeaturesController < AuthenticatedController
  before_action :assign_feature
  load_and_authorize_resource class: Flipper::Feature, id_param: :name

  def update
    @feature.enable_actor(current_user)

    redirect_back fallback_location: boards_path
  end

  def destroy
    @feature.disable_actor(current_user)

    redirect_back fallback_location: boards_path
  end

  private

  def assign_feature
    @feature = Flipper.feature(params[:name])
  end
end
