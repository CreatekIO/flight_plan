require 'rails_helper'

RSpec.describe PullRequestRefresher do
  describe '#run' do
    let(:repo) { create(:repo) }
    let(:remote_url) { repo.remote_url }
    let!(:pull_request) { create(:pull_request, repo: repo) }
    let(:state) { 'open' }

    subject { described_class.new(pull_request) }

    let(:gh_pr_payload) do
      {
        id: pull_request.remote_id,
        number: pull_request.remote_number,
        state: state,
        head: { sha: 'abc1234', ref: "feature/#{pull_request.remote_number}-test" },
        base: { sha: '4321cba', ref: 'master' },
        user: { id: 1000 }
      }
    end

    let!(:gh_pr_stub) do
      stub_gh_get("pulls/#{pull_request.remote_number}") do
        gh_pr_payload
      end
    end

    let(:gh_reviews_payload) do
      [{ id: 1000 }, { id: 1001 }]
    end

    let!(:gh_reviews_stub) do
      stub_gh_get("pulls/#{pull_request.remote_number}/reviews") do
        gh_reviews_payload
      end
    end

    before do
      allow(PullRequest).to receive(:import).and_call_original
      allow(PullRequestReview).to receive(:import).and_call_original
    end

    it 'updates pull request itself' do
      subject.run

      aggregate_failures do
        expect(gh_pr_stub).to have_been_requested

        expect(PullRequest).to have_received(:import).with(
          gh_pr_payload,
          repo
        )
      end
    end

    context 'when pull request is open' do
      let(:state) { 'open' }

      it 'updates linked reviews' do
        subject.run

        aggregate_failures do
          expect(gh_reviews_stub).to have_been_requested

          gh_reviews_payload.each do |gh_review|
            expect(PullRequestReview).to have_received(:import).with(
              {
                review: gh_review,
                pull_request: gh_pr_payload
              },
              repo
            )
          end
        end
      end
    end

    context 'when pull request is closed' do
      let(:state) { 'closed' }

      it 'does not update linked reviews' do
        subject.run

        aggregate_failures do
          expect(gh_reviews_stub).not_to have_been_requested
          expect(PullRequestReview).not_to have_received(:import)
        end
      end
    end
  end
end
