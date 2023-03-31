module GitHubApiStubHelper
  JWT_REGEX = /([a-zA-Z0-9\-_]+\.){2}[a-zA-Z0-9\-_]+/

  def stub_gh_get(path, status: 200, &block)
    stub_gh_request(:get, path, status: status, &block)
      .with(query: hash_including({}))
  end

  def stub_gh_post(path, body, status: 201, &block)
    stub_gh_request(:post, path, status: status, &block)
      .with(body: body)
  end

  def stub_gh_put(path, body = hash_including({}), status: 200, &block)
    stub_gh_request(:put, path, status: status, &block)
      .with(body: body)
  end

  def stub_gh_delete(path, status: 204, &block)
    stub_gh_request(:delete, path, status: status, &block)
  end

  def expand_gh_url(path)
    return path if path.start_with?("http")

    "https://api.github.com/repos/#{slug}/#{path}"
  end

  def stub_gh_installation_token_request
    request = stub_gh_request(
      :post,
      "https://api.github.com/app/installations/{id}/access_tokens",
      status: 201
    ) do
      {
        token: generate(:github_server_token),
        expires_at: 1.hour.from_now.utc.iso8601
      }
    end

    request.with(headers: { 'Authorization' => /^Bearer #{JWT_REGEX}$/ })
  end

  private

  def stub_gh_request(verb, path, status:)
    response = if block_given?
      generated = yield
      generated.respond_to?(:call) ? generated : generated.to_json
    else
      ''
    end

    url = expand_gh_url(path)
    url = Addressable::Template.new(url) if url.include?('{')

    stub_request(verb, url).and_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: response
    )
  end
end

RSpec.configure do |config|
  config.include GitHubApiStubHelper

  config.before do
    # Generally want this to succeed so always stub it
    stub_gh_installation_token_request
  end
end
