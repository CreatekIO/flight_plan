require 'rails_helper'

RSpec.describe AnnouncePullRequestRule do
  let(:payload) do
    webhook_payload(:pull_request_opened).fetch(:pull_request)
  end

  let(:repo) { create(:repo) }
  let!(:board) { create(:board, repos: [repo]) }

  subject { PullRequest.import(payload, repo) }

  before do
    Flipper.enable(:broadcasts)

    stub_slack(board.slack_channel)
  end

  context 'PR opened' do
    it 'announces PR on Slack' do
      subject

      expect(slack_notifier).to have_sent_message(/pull request opened/i)
    end
  end

  context 'release PR opened' do
    def payload
      super.deep_merge(head: { ref: 'release/20210101-103000' })
    end

    it 'does not announce PR' do
      subject

      expect(slack_notifier).not_to have_received(:notify)
    end
  end

  context 'automated PR from Crowdin opened' do
    def payload
      super.deep_merge(head: { ref: 'i18n_develop' }, base: { ref: 'develop' })
    end

    it 'does not announce PR' do
      subject

      expect(slack_notifier).not_to have_received(:notify)
    end
  end
end
