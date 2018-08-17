module GitHubApiStubHelper
  def stub_gh_get(path, status: 200, &block)
    stub_gh_request(:get, path, status: status, &block)
      .with(query: hash_including({}))
  end

  def stub_gh_post(path, body, status: 201, &block)
    stub_gh_request(:post, path, status: status, &block)
      .with(body: body)
  end

  def stub_gh_delete(path, status: 204, &block)
    stub_gh_request(:delete, path, status: status, &block)
  end

  private

  def stub_gh_request(verb, path, status:)
    response = block_given? ? yield.to_json : ''

    stub_request(verb, "https://api.github.com/repos/#{remote_url}/#{path}")
      .and_return(status: status, headers: { 'Content-Type' => 'application/json' }, body: response)
  end
end

RSpec.configure do |config|
  config.include GitHubApiStubHelper
end
