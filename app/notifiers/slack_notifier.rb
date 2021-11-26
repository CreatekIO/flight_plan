class SlackNotifier
  def initialize(channel)
    @channel = channel.to_s
  end

  def notify(text, attachments: [], **options)
    if skip_sending?
      Rails.logger.warn("Skipping Slack notification #{text}") if Rails.env.production?
      return true
    end

    slack_client.chat_postMessage(
      options.reverse_merge(
        channel: channel,
        text: text,
        attachments: proceess_attachments(attachments),
        as_user: true
      )
    )
  end

  private

  def channel
    return @channel if @channel.starts_with?('#')

    "##{@channel}"
  end

  def proceess_attachments(attachments)
    Array.wrap(attachments).map! do |attachment|
      attachment[:fallback] ||= attachment[:title]
      attachment
    end
  end

  def skip_sending?
    ENV['SLACK_API_TOKEN'].blank? || @channel.remove('#').blank?
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new
  end
end
