class SlackNotifier
  class << self
    delegate :notify, to: :new
  end

  def notify(text, channel:, attachments: [], **options)
    if skip_sending?(channel)
      Rails.logger.warn("Skipping Slack notification #{text}") if Rails.env.production?
      return true
    end

    slack_client.chat_postMessage(
      options.reverse_merge(
        channel: process_channel(channel.to_s),
        text: text,
        attachments: process_attachments(attachments),
        as_user: true
      )
    )
  end

  private

  def process_channel(channel)
    return channel if channel.starts_with?('#')

    "##{channel}"
  end

  def process_attachments(attachments)
    Array.wrap(attachments).map! do |attachment|
      attachment[:fallback] ||= attachment[:title]
      attachment
    end
  end

  def skip_sending?(channel)
    ENV['SLACK_API_TOKEN'].blank? || channel.to_s.remove('#').blank?
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new
  end
end
