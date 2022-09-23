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
    Flipper.enable(:automation)

    described_class.enable!(board)

    stub_slack
  end

  context 'PR opened' do
    it 'announces PR on Slack' do
      subject

      expect(slack_notifier).to have_sent_message(
        /pull request opened/i,
        to: board.slack_channel
      )
    end

    context 'custom slack channel set' do
      before do
        BoardRule.for(board: board, rule: described_class).tap do |rule|
          rule.settings[:slack_channel] = '#custom'
          rule.save!
        end
      end

      it 'sends message to Slack on custom channel' do
        subject

        expect(slack_notifier).to have_sent_message(
          /pull request opened/i,
          to: '#custom'
        )
      end
    end

    context 'feature disabled for board' do
      before do
        BoardRule.where(board: board, rule_class: described_class.name).delete_all
      end

      it 'does not announce PR' do
        subject

        expect(slack_notifier).not_to have_received(:notify)
      end
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

  context 'PR is already closed (but the first time we\'ve been notified)' do
    let(:payload) do
      webhook_payload(:pull_request_merged).fetch(:pull_request)
    end

    it 'does not announce PR' do
      subject

      expect(slack_notifier).not_to have_received(:notify)
    end
  end
end
