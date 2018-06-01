class Api::BaseController < ActionController::Base
  before_action :authenticate_user

  private

  def authenticate_user
    authenticate_or_request_with_http_token do |token, options|
      key, secret = token.split(':')
      key == ENV.fetch('USER_API_KEY') && secret == ENV.fetch('USER_API_SECRET')
    end
  end

  def request_http_token_authentication(realm = 'Application', message = nil)
    self.headers['WWW-Authenticate'] = %(Token realm="#{realm.gsub(/"/, '')}")
    render json: { error: 'HTTP Token: Access denied.' }, status: :unauthorized
  end

  def render_error(messages, status: :unprocessable_entity)
    render json: { errors: Array(messages) }, status: status
  end
end
