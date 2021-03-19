require 'rails_helper'

RSpec.describe PullRequestReview, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to belong_to(:pull_request).with_primary_key(:remote_id).optional }
    it { is_expected.to belong_to(:reviewer).with_primary_key(:uid).conditions(provider: 'github').optional }

    describe '.import' do
      let(:payload) { webhook_payload(:pull_request_review) }
      let(:repo) { create(:repo) }

      let!(:pull_request) do
        create(
          :pull_request,
          repo: repo,
          remote_id: payload[:pull_request][:id],
          number: payload[:pull_request][:number]
        )
      end

      subject(:review) { described_class.import(payload, repo) }

      context 'when review is not in the database' do
        it 'imports review details correctly' do
          expect(review.reload.attributes).to include(
            'remote_id' => payload[:review][:id],
            'state' => 'approved',
            'sha' => payload[:pull_request][:head][:sha],
            'url' => payload[:review][:html_url],
            'reviewer_remote_id' => payload[:review][:user][:id],
            'reviewer_username' => payload[:review][:user][:login],
            'remote_created_at' => Time.zone.parse(payload[:review][:submitted_at])
          )
        end

        it 'links to referenced pull_request' do
          expect(review.reload.pull_request).to eq(pull_request)
        end

        it 'links to passed-in repo' do
          expect(review.reload.repo).to eq(repo)
        end

        context 'with referenced user present in the database' do
          let!(:user) { create(:user, uid: payload[:review][:user][:id]) }

          it 'links to referenced reviewer' do
            expect(review.reload.reviewer).to eq(user)
          end
        end
      end

      context 'when review is already in the database' do
        let(:payload) do
          webhook_payload(:pull_request_review).deep_merge!(review: { state: 'CHANGES_REQUESTED' })
        end

        let!(:existing_review) do
          old_payload = webhook_payload(:pull_request_review)
          repo.pull_request_reviews.create!(
            remote_id: old_payload[:review][:id],
            state: old_payload[:review][:state]
          )
        end

        it 'doesn\'t create a new record' do
          expect {
            subject
          }.not_to change(described_class, :count)
        end

        it 'updates existing record' do
          subject

          expect(existing_review.reload.state).to eq('changes_requested')
        end
      end
    end
  end
end
