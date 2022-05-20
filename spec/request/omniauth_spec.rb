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
        get user_github_omniauth_authorize_path

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
          post user_github_omniauth_authorize_path
        }.to raise_error(ActionController::InvalidAuthenticityToken)
      end
    end
  end

  describe 'POST /users/auth/:provider/callback' do
    let(:user) { build(:user) }

    subject { post user_github_omniauth_callback_path }

    attr_reader :warden

    before do
      stub_omniauth(user: user, token: github_token)

      Warden.on_next_request do |proxy|
        @warden = proxy
      end
    end

    describe 'redirect location' do
      let(:github_token) { 'gho_token' }
      let!(:boards) { create_pair(:board) }
      let(:board) { boards.last }

      context 'with no cookie set' do
        it 'redirects to root' do
          subject

          expect(response).to redirect_to(root_path)
        end

        context 'user tries to access board' do
          before do
            get board_path(board)
          end

          it 'redirects to stored location' do
            subject

            expect(response).to redirect_to(board_path(board))
          end
        end
      end

      context 'with board ID stored in cookie' do
        before do
          user.save!
          sign_in(user)
          get board_path(board)
          delete destroy_user_session_path

          expect(cookies[:last_board_id]).to be_present
        end

        it 'redirects to board specified by cookie' do
          subject

          expect(response).to redirect_to(board_path(board))
        end
      end
    end

    describe 'token storage' do
      context 'no token stored' do
        context 'signing in via OAuth app' do
          let(:github_token) { 'gho_token' }

          it 'adds token within hash' do
            subject

            expect(warden.session['github.token']).to eq('oauth' => github_token)
          end
        end

        context 'signing in via app' do
          let(:github_token) { 'ghu_token' }

          it 'adds token within hash' do
            subject

            expect(warden.session['github.token']).to eq('app' => github_token)
          end
        end
      end

      context 'with token already stored' do
        before do
          user.save!
          sign_in user, github_token: existing_token
        end

        context 'in string format' do
          let(:existing_token) { 'gho_existing_token' }

          context 'signing in via OAuth app' do
            let(:github_token) { 'gho_token' }

            it 'adds token within hash, overwriting old token' do
              subject

              expect(warden.session['github.token']).to eq('oauth' => github_token)
            end
          end

          context 'signing in via app' do
            let(:github_token) { 'ghu_token' }

            it 'adds token within hash and keeps existing token' do
              subject

              expect(warden.session['github.token']).to eq(
                'oauth' => existing_token,
                'app' => github_token
              )
            end
          end
        end

        context 'in hash format' do
          let(:existing_token) do
            { 'oauth' => 'gho_existing_token' }
          end

          context 'signing in via OAuth app' do
            let(:github_token) { 'gho_token' }

            it 'adds token within hash, overwriting old token' do
              subject

              expect(warden.session['github.token']).to eq('oauth' => github_token)
            end
          end

          context 'signing in via app' do
            let(:github_token) { 'ghu_token' }

            it 'adds token within hash and keeps existing token' do
              subject

              expect(warden.session['github.token']).to eq(
                existing_token.merge('app' => github_token)
              )
            end
          end
        end
      end
    end
  end
end
