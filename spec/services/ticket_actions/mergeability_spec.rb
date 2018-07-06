require 'rails_helper'

RSpec.describe TicketActions::Mergeability do
  subject { described_class.new(pull_request) }

  describe '#next_action' do
    let(:repo) { build_stubbed(:repo) }

    let(:pull_request) do
      build_stubbed(:pull_request, repo: repo, merge_status: merge_status)
    end

    context 'when PR can be merged' do
      let(:merge_status) { true }

      it 'tells user to merge PR' do
        expect(subject.next_action).to eq(
          TicketActions::PositiveAction.new('Merge it!', urls: "#{pull_request.html_url}#partial-pull-merging")
        )
      end
    end

    context 'when PR has merge conflicts' do
      let(:merge_status) { false }

      it 'tells user to fix merge conflicts' do
        expect(subject.next_action).to eq(
          TicketActions::NegativeAction.new('Fix merge conflicts', urls: pull_request.html_url)
        )
      end
    end

    context 'when PR merge status is unknown' do
      let(:merge_status) { nil }

      it 'tells user to wait' do
        expect(subject.next_action).to eq(
          TicketActions::NeutralAction.new('Wait for merge check', urls: pull_request.html_url)
        )
      end
    end
  end
end
