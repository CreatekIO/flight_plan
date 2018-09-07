require 'rails_helper'

RSpec.describe TicketActions::PullRequestStatuses, type: :ticket_action do
  subject { described_class.new(pull_request) }

  describe '#next_action' do
    let(:repo) { create(:repo) }
    let(:pull_request) { build_stubbed(:pull_request, repo: repo) }
    let(:status_context) { 'service' }
    let(:service_url) do
      { url: url(status_context), title: description(status_context) }
    end

    def url(name)
      "https://ci.#{name}.test/#{pull_request.remote_number}"
    end

    def description(name)
      "From #{name}"
    end

    def create_status(state, datetime = Time.now, context: status_context, **attrs)
      create(
        :commit_status,
        context: context,
        state: state,
        sha: pull_request.remote_head_sha,
        repo: repo,
        url: url(context),
        description: description(context),
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
        new_sha = generate(:sha)
        pull_request.remote_head_sha = new_sha

        create_status(:failure, sha: new_sha)
      end

      it 'uses latest status (failure)' do
        expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_url])
      end
    end

    context 'with statuses from different services' do
      let(:service_1_url) do
        { url: url('service_1'), title: description('service_1') }
      end

      let(:service_2_url) do
        { url: url('service_2'), title: description('service_2') }
      end

      context 'both pending' do
        before do
          create_status(:pending, context: 'service_1')
          create_status(:pending, context: 'service_2')
        end

        it 'tell user to wait for both services' do
          expect(subject.next_action).to be_a_neutral_action('Wait for checks', urls: [service_1_url, service_2_url])
        end
      end

      context 'both unsuccessful' do
        before do
          create_status(:failure, context: 'service_1')
          create_status(:error, context: 'service_2')
        end

        it 'tell user to fix both issues' do
          expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_1_url, service_2_url])
        end
      end

      context 'one failing, one successful' do
        before do
          create_status(:success, context: 'service_1')
          create_status(:failure, context: 'service_2')
        end

        it 'tell user to fix failing issue' do
          expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_2_url])
        end
      end

      context 'one failing, one pending' do
        before do
          create_status(:pending, context: 'service_1')
          create_status(:failure, context: 'service_2')
        end

        it 'tell user to fix failing issue' do
          expect(subject.next_action).to be_a_negative_action('Fix issues', urls: [service_2_url])
        end
      end
    end
  end
end
