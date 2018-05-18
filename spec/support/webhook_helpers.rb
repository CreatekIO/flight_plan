module WebhookHelpers
  def webhook_json(name)
    Rails.root.join("spec/support/fixtures/webhooks", "#{name}.json").read
  end

  def webhook_payload(name)
    JSON.parse(
      webhook_json(name),
      object_class: HashWithIndifferentAccess
    )
  end
end

RSpec.configure do |config|
  config.include WebhookHelpers, type: :model
end
