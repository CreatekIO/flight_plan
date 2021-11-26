class ApplicationController < ActionController::Base
  helper_method :feature?

  private

  def feature?(name)
    Flipper.enabled?(name, current_user) || feature_in_params?(name)
  end

  def feature_in_params?(name)
    @param_features ||= params[:__features__].to_s.split(',')

    @param_features.include?(name.to_s)
  end
end
