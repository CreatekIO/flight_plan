class Api::BaseController < ActionController::Base
  before_action :authenticate_user

  private

  def authenticate_user
    authenticate_or_request_with_http_token do |token, options|
      key, secret = token.split(':')
      key == ENV['USER_API_KEY'] && secret == ENV['USER_API_SECRET']
    end
  end
end
