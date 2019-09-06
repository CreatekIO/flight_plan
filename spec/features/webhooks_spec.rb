require 'rails_helper'

RSpec.feature 'Webhooks', type: :webhook do
  let(:webhook_secret) { SecureRandom.hex }

  around do |example|
    key = 'GITHUB_WEBHOOK_SECRET'
    original = ENV[key]
    ENV[key] = webhook_secret

    example.run

    original ? ENV[key] = original : ENV.delete(key)
  end

  around do |example|
    Sidekiq::Testing.fake! do
      example.run
      Sidekiq::Worker.clear_all
    end
  end

  let!(:repo) do
    create(:repo, name: 'FlightPlan', remote_url: 'CreatekIO/flight_plan').tap do
      # Ensure repo can be seen by Puma server
      Repo.connection.commit_transaction
    end
  end

  event_type :pull_request do
    action :created do
      let(:payload) do
        {
          repository: { full_name: repo.remote_url },
          pull_request: {
            id: 1,
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
            payload[:pull_request][:id]
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
