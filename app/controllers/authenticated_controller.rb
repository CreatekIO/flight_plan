class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  private

  def current_user_github_token
    user_session['github.token']
  end
end
