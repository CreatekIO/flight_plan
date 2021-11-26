module SlackHelpers
  def stub_slack(channel)
    allow(SlackNotifier).to receive(:new).with(channel).and_return(slack_notifier)
  end

  def slack_notifier
    @slack_notifier ||= double('SlackNotifier', notify: true)
  end

  def have_sent_message(title, attachments = a_hash_including(:attachments))
    have_received(:notify).with(title, attachments)
  end
end

RSpec.configure do |config|
  config.include SlackHelpers
end
