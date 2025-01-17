require 'rails_helper'

RSpec.describe UnsuccessfulBuildOnMajorBranchRule do
  let(:payload) do
    webhook_payload(:status).merge(
      sha: status_branch.latest_head.head_sha,
      state: state,
      context: context,
      description: description
    )
  end

  let(:repo) { create(:repo) }
  let!(:board) { create(:board, repos: [repo]) }
  let!(:status_branch) { create(:branch, :with_head, name: branch_name, repo: repo) }

  let(:state) { 'failure' }
  let(:context) { 'ci' }
  let(:description) { nil }

  subject { CommitStatus.import(payload, repo) }

  before do
    Flipper.enable(:broadcasts)
    Flipper.enable(:automation)

    described_class.enable!(board)

    stub_slack
  end

  context 'on master branch' do
    let(:branch_name) { 'master' }

    context 'status = failure' do
      let(:state) { 'failure' }

      it 'sends message to Slack' do
        subject

        expect(slack_notifier).to have_sent_message(
          /build failed on `#{branch_name}`/i,
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
            /build failed on `#{branch_name}`/i,
            to: '#custom'
          )
        end
      end

      context 'from Buildkite' do
        let(:context) { 'buildkite/my-pipeline' }

        context 'build was cancelled by Buildkite' do
          let(:description) { 'Build #1234 canceled' }

          it 'does not post any messages to Slack' do
            subject

            expect(slack_notifier).not_to have_received(:notify)
          end
        end

        context 'build was cancelled by user' do
          let(:description) { 'Build #1234 canceled by Users Name' }

          it 'does not post any messages to Slack' do
            subject

            expect(slack_notifier).not_to have_received(:notify)
          end
        end

        context 'build is failing' do
          let(:description) { 'Build #1234 is failing' }

          it 'does not post any messages to Slack' do
            subject

            expect(slack_notifier).not_to have_received(:notify)
          end
        end

        context 'build skipped' do
          let(:state) { 'error' }
          let(:description) { 'Build #1234 skipped' }

          it 'does not post any messages to Slack' do
            subject

            expect(slack_notifier).not_to have_received(:notify)
          end
        end
      end

      context 'context is ignored' do
        before do
          BoardRule.for(board: board, rule: described_class).tap do |rule|
            rule.settings[:ignored_contexts] = "noisy|#{context}"
            rule.save!
          end
        end

        it 'does not post any messages to Slack' do
          subject

          expect(slack_notifier).not_to have_received(:notify)
        end
      end

      context 'rule disabled for board' do
        before do
          BoardRule.where(board: board, rule_class: described_class.name).delete_all
        end

        it 'does not post any messages to Slack' do
          subject

          expect(slack_notifier).not_to have_received(:notify)
        end
      end
    end

    context 'status = error' do
      let(:state) { 'error' }

      it 'sends message to Slack' do
        subject

        expect(slack_notifier).to have_sent_message(/build failed on `#{branch_name}`/i)
      end
    end

    context 'status = success' do
      let(:state) { 'success' }

      it 'does not post any messages to Slack' do
        subject

        expect(slack_notifier).not_to have_received(:notify)
      end
    end
  end

  context 'on multiple branches' do
    let(:branch_name) { branch_names.first }

    before do
      create(:branch, name: branch_names.second, repo: repo, head: status_branch.latest_head.head_sha)
    end

    context 'and one is master' do
      let(:branch_names) { %w[configuration_changes master] }

      it 'sends message to Slack' do
        subject

        expect(slack_notifier).to have_sent_message(/build failed on `master`/i)
      end
    end

    context 'all considered major' do
      let(:branch_names) { %w[develop master] }

      it 'sends message to Slack with all branch names' do
        subject

        expect(slack_notifier).to have_sent_message(
          /build failed on `develop` and `master`/i
        )
      end
    end
  end

  context 'on feature branch' do
    let(:branch_name) { 'feature/#123-some-feature' }

    it 'does not post any messages to Slack' do
      subject

      expect(slack_notifier).not_to have_received(:notify)
    end
  end
end
