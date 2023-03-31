class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  helper_method :current_user_github_token

  private

  def current_user_github_token
    OctokitClient::Token.read_from_session(user_session)
  end
end
