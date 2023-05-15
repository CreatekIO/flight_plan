class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :feature?

  private

  def last_board_id
    cookies.signed.permanent[:last_board_id]
  end

  def last_board_id=(id)
    cookies.signed.permanent[:last_board_id] = id
  end

  def signed_in_root_path(_resource_or_scope)
    return board_path(last_board_id) if last_board_id.present?

    super
  end

  def feature?(name)
    Flipper.enabled?(name, current_user) || feature_in_params?(name)
  end

  def feature_in_params?(name)
    @param_features ||= params[:__features__].to_s.split(',')

    @param_features.include?(name.to_s)
  end
end
