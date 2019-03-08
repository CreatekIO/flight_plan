class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  helper_method :current_page, :next_page

  private

  def current_page
    @current_page ||= (params[:page].presence || 1).to_i
  end

  def next_page
    current_page + 1
  end
end
