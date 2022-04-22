class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  private

  def current_user_github_token
    OctokitClient::Token.read_from_session(user_session)
  end
end
