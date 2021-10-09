class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include OctokitClient

  octokit_methods :organization_member?

  before_action :ensure_org_member, only: :github

  def github
    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      user_session['github.token'] = auth.credentials.token
    else
      session['devise.github_data'] = auth
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path, alert: params[:message].presence || 'Unable to sign in via GitHub'
  end

  private

  def ensure_org_member
    login = auth.extra.raw_info.login
    return if allowed_orgs.any? { |org| octokit_organization_member?(org, login) }

    redirect_to root_path, alert: 'Not a member of any permitted organisations' and return
  end

  def octokit_client_options
    { access_token: auth.credentials.token }
  end

  def legacy_client
    @legacy_client ||= OctokitClient.legacy_client
  end

  def octokit_organization_member?(org, username)
    from_user_token = super
    from_legacy = legacy_client.organization_member?(org, username)

    return from_legacy if from_legacy == from_user_token

    payload = {
      org: org,
      username: username,
      token_prefix: auth.credentials.token.split('_').first,
      from_user_token: from_user_token,
      from_legacy: from_legacy,
      org_memberships_method: octokit.org_memberships.map(&:organization).map(&:login)
    }

    logger.warn("Org member? mismatch: #{payload.inspect}")

    Bugsnag.notify('Org member? mismatch') do |report|
      report.add_tab(:debugging, payload)
    end

    from_legacy
  end

  def user
    @user ||= User.from_omniauth(auth)
  end

  def auth
    request.env['omniauth.auth']
  end

  def allowed_orgs
    ENV['PERMITTED_GITHUB_ORGS'].to_s.split(',').presence || %w[CreatekIO]
  end
end
