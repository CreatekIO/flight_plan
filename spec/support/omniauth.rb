OmniAuth.config.test_mode = true

module OmniAuthTestHelper
  def stub_omniauth(user:, token: 'ghu_github_token_1234')
    OmniAuth.config.add_mock(
      :github,
      credentials: { token: token },
      uid: user.uid,
      info: {
        name: user.name.presence || user.username,
        nickname: user.username,
      },
      extra: {
        raw_info: {
          login: user.username
        }
      }
    )

    stub_gh_request(
      :get,
      "https://api.github.com/orgs/CreatekIO/members/#{user.username}",
      status: 204
    )
  end
end

RSpec.configure do |config|
  config.before(:each) do
    OmniAuth.config.mock_auth[:github] = nil
  end

  config.include OmniAuthTestHelper
end
