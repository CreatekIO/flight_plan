module GitHubApiStubHelper
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
    "https://api.github.com/repos/#{remote_url}/#{path}"
  end

  private

  def stub_gh_request(verb, path, status:)
    response = block_given? ? yield.to_json : ''

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
end
