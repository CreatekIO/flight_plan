class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: ENV['BASIC_AUTH_USER'], password: ENV['BASIC_AUTH_PASSWORD'] if Rails.env.production?
  protect_from_forgery with: :exception
  load_and_authorize_resource

  def current_user
    true
  end
end
