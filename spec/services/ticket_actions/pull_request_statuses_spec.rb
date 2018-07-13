require 'rails_helper'

RSpec.describe TicketActions::PullRequestStatuses, type: :ticket_action do
  subject { described_class.new(pull_request) }

  describe '#next_action' do
    let(:repo) { create(:repo) }
    let(:pull_request) { build_stubbed(:pull_request, repo: repo) }
    let(:service_url) { "https://ci.service.test/#{pull_request.remote_number}" }

    def create_status(state, datetime = Time.now, **attrs)
      create(
        :commit_status,
        state: state,
        sha: pull_request.remote_head_sha,
        repo: repo,
        url: service_url,
        created_at: datetime,
        remote_created_at: datetime,
        **attrs
      )
    end

    context 'with pending status' do
      before do
        create_status(:pending)
      end

      it 'tells users to wait' do
        expect(subject.next_action).to be_a_neutral_action('Wait for checks', urls: [service_url])
      end
    end

    context 'with error status' do
      before do
        create_status(:error)
      end

      it 'tells user to fix PR' do
        expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_url])
      end
    end

    context 'with pending, then failing status' do
      before do
        3.times do |n|
          create_status(:pending, (10 - n).minutes.ago)
        end

        create_status(:failure, 1.minute.ago)
      end

      it 'tells user to fix PR' do
        expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_url])
      end

      context 'followed by fixed status' do
        before do
          create_status(:success)
        end

        it 'returns nil' do
          expect(subject.next_action).to be_nil
        end
      end
    end

    context 'with pending, then successful status' do
      before do
        3.times do |n|
          create_status(:pending, (10 - n).minutes.ago)
        end

        create_status(:success, 1.minute.ago)
      end

      it 'returns nil' do
        expect(subject.next_action).to be_nil
      end

      context 'followed by failing status' do
        before do
          create_status(:failure)
        end

        it 'tells user to fix PR' do
          expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_url])
        end
      end
    end

    context 'with older status from a previous SHA' do
      before do
        create_status(:success)

        # Mimic push to PR branch
        new_sha = SecureRandom.hex(20)
        pull_request.remote_head_sha = new_sha

        create_status(:failure, sha: new_sha)
      end

      it 'uses latest status (failure)' do
        expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_url])
      end
    end

    context 'with statuses from different services' do
      let(:service_1_url) { service_url.sub('service', 'service_1') }
      let(:service_2_url) { service_url.sub('service', 'service_2') }

      context 'both pending' do
        before do
          create_status(:pending, context: 'service_1', url: service_1_url)
          create_status(:pending, context: 'service_2', url: service_2_url)
        end

        it 'tell user to wait for both services' do
          expect(subject.next_action).to be_a_neutral_action('Wait for checks', urls: [service_1_url, service_2_url])
        end
      end

      context 'both unsuccessful' do
        before do
          create_status(:failure, context: 'service_1', url: service_1_url)
          create_status(:error, context: 'service_2', url: service_2_url)
        end

        it 'tell user to fix both issues' do
          expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_1_url, service_2_url])
        end
      end

      context 'one failing, one successful' do
        before do
          create_status(:success, context: 'service_1', url: service_1_url)
          create_status(:failure, context: 'service_2', url: service_2_url)
        end

        it 'tell user to fix failing issue' do
          expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_2_url])
        end
      end

      context 'one failing, one pending' do
        before do
          create_status(:pending, context: 'service_1', url: service_1_url)
          create_status(:failure, context: 'service_2', url: service_2_url)
        end

        it 'tell user to fix failing issue' do
          expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_2_url])
        end
      end
    end
  end
end
