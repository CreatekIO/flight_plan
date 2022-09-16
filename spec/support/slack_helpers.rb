module SlackHelpers
  def stub_slack
    allow(SlackNotifier).to receive(:new).and_return(slack_notifier)
  end

  def slack_notifier
    @slack_notifier ||= double('SlackNotifier', notify: true)
  end

  def have_sent_message(text, attachments: kind_of(Enumerable), to: nil)
    options = { attachments: attachments }
    options[:channel] = to.presence || instance_of(String)

    have_received(:notify).with(text, a_hash_including(options))
  end
end

RSpec.configure do |config|
  config.include SlackHelpers
end
