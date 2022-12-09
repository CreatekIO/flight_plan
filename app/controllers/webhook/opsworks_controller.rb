class Webhook::OpsworksController < Webhook::BaseController
  before_action :verify_signature

  DIGEST = 'sha256'.freeze

  def create
    head :created
  end

  private

  def verify_signature
    body = request.body.tap(&:rewind).read
    signature = request.headers['X-Signature'].to_s
    expected_signature = "sha256=#{OpenSSL::HMAC.hexdigest(DIGEST, webhook_secret, body)}"

    return if ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)

    payload = {
      expected: expected_signature,
      actual: signature
    }

    logger.tagged('OPSWORKS') do
      logger.warn("Signature mismatch! #{payload.inspect}")
    end

    Bugsnag.notify('OpsWorks signature mismatch') do |report|
      report.add_tab(:debugging, payload)
    end
  end

  def webhook_secret
    ENV['OPSWORKS_WEBHOOK_SECRET']
  end
end
