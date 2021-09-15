require 'rails_helper'

RSpec.describe 'Webhooks', type: :request do
  let(:webhook_secret) { SecureRandom.hex }

  before do |example|
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GITHUB_WEBHOOK_SECRET').and_return(webhook_secret)
  end

  around do |example|
    previous_value = ActionController::Base.allow_forgery_protection

    Sidekiq::Testing.fake! do
      begin
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = previous_value
        Sidekiq::Worker.clear_all
      end
    end
  end

  let!(:repo) do
    create(:repo, name: 'FlightPlan', slug: 'CreatekIO/flight_plan')
  end

  event_type :pull_request do
    action :created do
      let(:payload) do
        {
          repository: {
            id: repo.remote_id,
            full_name: repo.slug
          },
          pull_request: {
            id: generate(:pr_remote_id),
            mergeable: merge_status,
            head: { ref: 'b', sha: 'b' },
            base: { ref: 'a', sha: 'a' },
            user: { id: 1 }
          }
        }
      end

      context 'merge status unknown' do
        let(:merge_status) { nil }

        it 'enqueues a worker to refresh merge status' do
          expect {
            deliver_webhook(payload)
          }.to change(PullRequest, :count).by(1)

          expect(PullRequestRefreshWorker).to have_enqueued_sidekiq_job(
            PullRequest.reorder(:created_at).last.id
          ).in(1.minute)
        end
      end

      context 'merge status known' do
        let(:merge_status) { true }

        it 'doesn\'t enqueue a worker' do
          expect {
            deliver_webhook(payload)
          }.to change(PullRequest, :count).by(1)

          expect(PullRequestRefreshWorker).not_to have_enqueued_sidekiq_job
        end
      end
    end
  end
end
