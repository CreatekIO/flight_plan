# See https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app
class App
  include OctokitClient

  JWT_ALGO = 'RS256'.freeze

  APP_ID = ENV.fetch('GITHUB_APP_ID')

  PRIVATE_KEY = OpenSSL::PKey::RSA.new(
    ENV.fetch('GITHUB_PRIVATE_KEY').gsub('\n', "\n")
  )

  # Installation tokens last for 1 hour, so set our TTL to a bit less
  CACHE_TTL = 55.minutes

  class << self
    delegate :access_token_for, :uninstall, to: :new
  end

  # Use this value for Octokit::Client#access_token
  def access_token_for(installation_id:)
    Rails.cache.fetch("octokit:installation_token/#{installation_id}", expires_in: CACHE_TTL) do
      octokit.create_installation_access_token(installation_id).token
    end
  end

  # https://docs.github.com/en/rest/reference/apps#delete-an-installation-for-the-authenticated-app
  def uninstall(installation_id:)
    octokit.delete("/app/installations/#{installation_id}") # no method for this yet in Octokit
    octokit.last_response.status == 204
  end

  private

  def octokit_client_options
    { bearer_token: jwt, access_token: nil }
  end

  def jwt
    now = Time.find_zone!('UTC').now

    JWT.encode(
      {
        iss: APP_ID,
        iat: (now - 30.seconds).to_i, # allow for clock drift
        exp: (now + 10.minutes).to_i  # 10 mins is max allowed
      },
      PRIVATE_KEY,
      JWT_ALGO
    )
  end
end
