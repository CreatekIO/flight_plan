class GithubWebhookFake
  HMAC_DIGEST = OpenSSL::Digest.new('sha1')
  USER_AGENT = 'GitHub-Hookshot/0000000'.freeze
  CONTENT_TYPE = 'application/x-www-form-urlencoded'.freeze

  def self.generate_request(event:, payload:, secret:)
    # Payload is JSON, even for URL-encoded deliveries
    body = {
      payload: payload.is_a?(String) ? payload : JSON.generate(payload)
    }.to_query

    signature = OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)

    # See: https://developer.github.com/webhooks/#delivery-headers
    headers = {
      'Content-Length' => body.bytesize.to_s,
      'Content-Type' => CONTENT_TYPE,
      'User-Agent' => USER_AGENT,
      'X-GitHub-Delivery' => SecureRandom.uuid,
      'X-GitHub-Event' => event.to_s,
      'X-Hub-Signature' => "sha1=#{signature}"
    }

    [headers, body]
  end

  def initialize(url)
    @webhook_url = url
  end

  def deliver(event:, payload:, secret:)
    headers, body = self.class.generate_request(
      event: event,
      payload: payload,
      secret: secret
    )

    connection.post do |request|
      request.url(webhook_url)
      request.body = body
      request.headers = headers
    end
  end

  private

  attr_reader :webhook_url

  def connection
    @connection ||= Faraday.new do |conn|
      conn.response :logger if ENV['ENABLE_WEBHOOK_FAKE_LOG'].present?
      conn.adapter Faraday.default_adapter
    end
  end
end
