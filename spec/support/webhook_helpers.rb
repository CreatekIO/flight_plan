module WebhookHelpers
  extend ActiveSupport::Concern

  module ClassMethods
    def event_type(event, &block)
      let(:event_type) { event }

      context("`#{event}` event", &block)
    end

    def action(name, &block)
      context("`#{name}` action", &block)
    end
  end

  def webhook_json(name)
    Rails.root.join("spec/support/fixtures/webhooks", "#{name}.json").read
  end

  def webhook_payload(name)
    JSON.parse(
      webhook_json(name),
      object_class: HashWithIndifferentAccess
    )
  end

  def deliver_webhook(payload, event: event_type)
    headers, request_body = GithubWebhookFake.generate_request(
      event: event,
      payload: payload,
      secret: webhook_secret
    )

    post webhook_github_url, params: request_body, headers: headers
  end
end

RSpec.configure do |config|
  config.include WebhookHelpers
end
