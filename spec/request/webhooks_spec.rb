require 'rails_helper'

RSpec.describe 'Webhooks', type: :request do
  let(:webhook_secret) { SecureRandom.hex }

  before do
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

  event_type :installation do
    let(:installation_id) { payload[:installation][:id] }

    action :created do
      let(:payload) { webhook_payload(:installation_created) }

      let(:existing_repo) do
        remote = payload[:repositories].first

        create(
          :repo,
          name: remote[:name],
          remote_id: remote[:id],
          slug: remote[:full_name],
          remote_installation_id: nil
        )
      end

      let(:slug) { existing_repo.slug }
      let(:old_webhook_id) { FactoryBot.generate(:github_id) }

      before do
        stub_gh_get('hooks') do
          [
            {
              id: old_webhook_id,
              config: { url: 'https://flightplan.createk.io/webhook/github' }
            },
            {
              id: old_webhook_id + 1,
              config: { url: 'https://circleci.com/hooks/github' }
            }
          ]
        end
      end

      let!(:webhook_delete_request) do
        stub_gh_delete("hooks/#{old_webhook_id}").with(
          headers: { 'Authorization' => /^token ghs_/ }
        )
      end

      it 'adds installation id to existing repo' do
        expect { deliver_webhook(payload) }
          .to change { existing_repo.reload.remote_installation_id }
          .from(nil)
          .to(payload[:installation][:id])
          .and not_change(Repo.where(remote_id: existing_repo.remote_id), :count)
      end

      it 'creates record for new repo' do
        remote = payload[:repositories].second

        query = Repo.where(
          remote_id: remote[:id],
          slug: remote[:full_name],
          remote_installation_id: installation_id
        ).where.not(deployment_branch: ['', nil], name: ['', nil])

        expect { deliver_webhook(payload) }
          .to change(query, :count).by(1)
      end

      it 'removes old webhook for existing repo' do
        deliver_webhook(payload)

        expect(webhook_delete_request).to have_been_requested
      end

      context 'user/org is not permitted to install app' do
        before do
          stub_const('InstallationImporter::ORGS', [])
        end

        let!(:installation_delete_request) do
          stub_gh_delete(
            "https://api.github.com/app/installations/#{installation_id}"
          ).with(
            headers: { 'Authorization' => /^Bearer #{GitHubApiStubHelper::JWT_REGEX}$/ }
          )
        end

        it 'does not change or create any repos' do
          aggregate_failures do
            expect { deliver_webhook(payload) }
              .to not_change { existing_repo.reload.attributes }
              .and not_change(Repo, :count)

            expect(webhook_delete_request).not_to have_been_requested
          end
        end

        it 'deletes installation' do
          deliver_webhook(payload)

          expect(installation_delete_request).to have_been_requested
        end
      end
    end

    action :deleted do
      let(:payload) { webhook_payload(:installation_deleted) }

      let!(:existing_repo) do
        remote = payload[:repositories].first

        create(
          :repo,
          name: remote[:name],
          remote_id: remote[:id],
          slug: remote[:full_name],
          remote_installation_id: installation_id
        )
      end

      it 'removes installation id from existing repo' do
        expect { deliver_webhook(payload) }
          .to change { existing_repo.reload.remote_installation_id }
          .from(payload[:installation][:id])
          .to(nil)
          .and not_change(Repo, :count)
      end
    end
  end

  event_type :installation_repositories do
    let(:installation_id) { payload[:installation][:id] }

    action :added do
      let(:payload) { webhook_payload(:installation_repositories_added) }
      let(:remote_repo) { payload[:repositories_added].first }

      let(:existing_repo) do
        create(
          :repo,
          name: remote_repo[:name],
          remote_id: remote_repo[:id],
          slug: remote_repo[:full_name],
          remote_installation_id: nil
        )
      end

      let(:slug) { existing_repo.slug }
      let(:old_webhook_id) { FactoryBot.generate(:github_id) }

      before do
        stub_gh_get('hooks') do
          [
            {
              id: old_webhook_id,
              config: { url: 'https://flightplan.createk.io/webhook/github' }
            },
            {
              id: old_webhook_id + 1,
              config: { url: 'https://circleci.com/hooks/github' }
            }
          ]
        end
      end

      let!(:webhook_delete_request) do
        stub_gh_delete("hooks/#{old_webhook_id}").with(
          headers: { 'Authorization' => /^token ghs_/ }
        )
      end

      it 'adds installation id to existing repo' do
        expect { deliver_webhook(payload) }
          .to change { existing_repo.reload.remote_installation_id }
          .from(nil)
          .to(payload[:installation][:id])
          .and not_change(Repo.where(remote_id: existing_repo.remote_id), :count)
      end

      it 'creates record for new repo' do
        query = Repo.where(
          remote_id: remote_repo[:id],
          slug: remote_repo[:full_name],
          remote_installation_id: installation_id
        ).where.not(deployment_branch: ['', nil], name: ['', nil])

        expect { deliver_webhook(payload) }
          .to change(query, :count).by(1)
      end

      it 'removes old webhook for existing repo' do
        deliver_webhook(payload)

        expect(webhook_delete_request).to have_been_requested
      end
    end

    action :removed do
      let(:payload) { webhook_payload(:installation_repositories_removed) }

      let!(:existing_repo) do
        remote = payload[:repositories_removed].first

        create(
          :repo,
          name: remote[:name],
          remote_id: remote[:id],
          slug: remote[:full_name],
          remote_installation_id: installation_id
        )
      end

      it 'removes installation id from existing repo' do
        expect { deliver_webhook(payload) }
          .to change { existing_repo.reload.remote_installation_id }
          .from(payload[:installation][:id])
          .to(nil)
          .and not_change(Repo, :count)
      end
    end
  end

  event_type :pull_request do
    let!(:repo) do
      create(:repo, name: 'FlightPlan', slug: 'CreatekIO/flight_plan')
    end

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
