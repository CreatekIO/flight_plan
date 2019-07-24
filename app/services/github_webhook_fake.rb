class GithubWebhookFake
  # See: https://developer.github.com/webhooks/#delivery-headers
  class GitHubWebhookMiddleware < Faraday::Middleware
    HMAC_DIGEST = OpenSSL::Digest.new('sha1')
    USER_AGENT = 'GitHub-Hookshot/0000000'.freeze

    def call(env)
      env.request_headers.merge!(
        'X-GitHub-Delivery' => SecureRandom.uuid,
        'X-Hub-Signature' => "sha1=#{generate_signature(env)}",
        'User-Agent' => USER_AGENT,
        'Content-Length' => env.body.bytesize.to_s
      )

      @app.call(env)
    end

    private

    def generate_signature(env)
      OpenSSL::HMAC.hexdigest(
        HMAC_DIGEST,
        env.request.context.fetch(:webhook_secret),
        env.body
      )
    end
  end

  def initialize(url)
    @webhook_url = url
  end

  def deliver(event:, payload:, secret:)
    connection.post do |request|
      request.url(webhook_url)
      # Payload is JSON, even for URL-encoded deliveries
      request.body = { payload: payload.is_a?(String) ? payload : JSON.generate(payload) }
      request.headers = { 'X-GitHub-Event' => event.to_s }
      request.options.context = { webhook_secret: secret }
    end
  end

  private

  attr_reader :webhook_url

  def connection
    @connection ||= Faraday.new do |conn|
      conn.request :url_encoded
      conn.use GitHubWebhookMiddleware
      conn.response :logger if ENV['ENABLE_WEBHOOK_FAKE_LOG'].present?

      conn.adapter Faraday.default_adapter
    end
  end
end
