class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    @user = User.from_omniauth(request.env["omniauth.auth"])

    login = request.env['omniauth.auth'].extra.raw_info.login
    unless Octokit.organization_member?('CreatekIO', login)
      raise 'Not a memeber of Createk'
    end

    session["github.token"] = request.env['omniauth.auth'][:credentials].token

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication
      set_flash_message(:notice, :success, :kind => "github") if is_navigational_format?
    else
      session["devise.github_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
