class SlackNotifier
  def notify(text, attachments: [], **options)
    return true if skip_sending?

    slack_client.chat_postMessage(
      options.reverse_merge(
        channel: ENV['SLACK_CHANNEL'],
        text: text,
        attachments: proceess_attachments(attachments),
        as_user: true
      )
    )
  end

  private

  def proceess_attachments(attachments)
    Array.wrap(attachments).map! do |attachment|
      attachment[:fallback] ||= attachment[:title]
      attachment
    end
  end

  def skip_sending?
    ENV['SLACK_API_TOKEN'].blank?
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new
  end
end
