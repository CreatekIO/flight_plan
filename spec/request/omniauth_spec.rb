require 'rails_helper'

RSpec.describe 'Omniauth', type: :request do
  # Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
  #
  # See:
  # - https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
  # - https://github.com/omniauth/omniauth/pull/809#issuecomment-512689882
  describe 'CVE-2015-9284' do
    describe 'GET /users/auth/:provider' do
      it 'does not allow GET requests to initial OmniAuth endpoint' do
        get '/users/auth/github'

        expect(response).not_to have_http_status(:redirect)
      end
    end

    describe 'POST /users/auth/:provider without CSRF token' do
      around do |example|
        allow_forgery_protection = ActionController::Base.allow_forgery_protection
        test_mode = OmniAuth.config.test_mode

        ActionController::Base.allow_forgery_protection = true
        OmniAuth.config.test_mode = false

        example.run

        ActionController::Base.allow_forgery_protection = allow_forgery_protection
        OmniAuth.config.test_mode = test_mode
      end

      it 'requires CSRF token for initial OmniAuth endpoint' do
        expect {
          post '/users/auth/github'
        }.to raise_error(ActionController::InvalidAuthenticityToken)
      end
    end
  end
end
