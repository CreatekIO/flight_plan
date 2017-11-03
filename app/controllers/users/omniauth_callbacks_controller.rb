class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_action :ensure_org_member

  def github
    session['github.token'] = auth.credentials.token

    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: 'github') if is_navigational_format?
    else
      session["devise.github_data"] = auth
      redirect_to new_user_registration_url
    end
  end

  private

  def ensure_org_member
    login = auth.extra.raw_info.login
    unless Octokit.organization_member?('CreatekIO', login)
      raise 'Not a memeber of Createk'
    end
  end

  def user
    @user ||= User.from_omniauth(auth)
  end

  def auth
    request.env['omniauth.auth']
  end

  def failure
    redirect_to root_path
  end
end
