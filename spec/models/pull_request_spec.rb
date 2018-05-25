require 'rails_helper'

RSpec.describe PullRequest do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to have_many(:pull_request_connections) }
    it { is_expected.to have_many(:tickets).through(:pull_request_connections) }
    it { is_expected.to have_many(:reviews).with_primary_key(:remote_id) }
  end

  describe '.import' do
    include_context 'board with swimlanes'
    include_context 'remote pull request'

    context 'when the pull request does not already exist' do
      it 'adds the pull_request to the repo' do
        expect {
          @pull_request = described_class.import(remote_pull_request, remote_repo)
        }.to change { repo.pull_request_models.count }.by(1)

        expect(@pull_request.remote_title).to eq('pull request title')
      end
    end

    context 'when the pull request exists' do
      it 'updates the pull request' do
        pull_request = create(:pull_request, remote_title: 'before title', repo: repo, remote_id: pull_request_id)

        expect {
          described_class.import(remote_pull_request, remote_repo)
        }.not_to change { repo.pull_request_models.count }

        expect(pull_request.reload.remote_title).to eq('pull request title')
      end
    end
  end

  describe '.find_by_remote' do
    let(:remote_pull_request_id) { 100 }
    let(:remote_pull_request) { { id: remote_pull_request_id } }
    let(:remote_repo) { { full_name: 'org_name/repo_name' } }
    let!(:repo) { create(:repo, remote_url: 'org_name/repo_name') }

    context 'when the pull request doesn\'t exist' do
      it 'builds a new pull request' do
        pull_request = described_class.find_by_remote(remote_pull_request, remote_repo)

        expect(pull_request).not_to be_persisted
      end
    end

    context 'when the pull request exists' do
      it 'finds the pull request' do
        create(:pull_request, repo: repo, remote_id: remote_pull_request_id)
        pull_request = described_class.find_by_remote(remote_pull_request, remote_repo)

        expect(pull_request).to be_persisted
      end
    end
  end

  describe '#merge_status=' do
    it 'transforms values from GitHub\'s API to our values' do
      aggregate_failures do
        expect(described_class.new(merge_status: nil).merge_status).to eq('merge_status_unknown')
        expect(described_class.new(merge_status: false).merge_status).to eq('merge_conflicts')
        expect(described_class.new(merge_status: true).merge_status).to eq('merge_ok')
      end
    end
  end

  describe '#update_pull_request_connections' do
    let(:repo) { create(:repo) }
    let(:branch_ticket) { create(:ticket, repo: repo) }
    let(:body_ticket) { create(:ticket, repo: repo) }

    def connection_counts
      pull_request.pull_request_connections.group(:ticket).count
    end

    context 'new pull request' do
      let(:pull_request) do
        build(
          :pull_request,
          repo: repo,
          remote_head_branch: "feature/##{branch_ticket.remote_number}-test",
          remote_body: "Connects ##{body_ticket.remote_number}"
        )
      end

      it 'creates connections from branch name and body' do
        expect {
          pull_request.save!
        }.to change {
          connection_counts
        }.to(branch_ticket => 1, body_ticket => 1)
      end
    end

    context 'existing pull request' do
      let(:pull_request) do
        create(
          :pull_request,
          repo: repo,
          remote_head_branch: "feature/##{branch_ticket.remote_number}-test",
          remote_body: "Connects ##{body_ticket.remote_number}"
        )
      end

      let(:new_branch_ticket) { create(:ticket, repo: repo) }
      let(:new_body_ticket) { create(:ticket, repo: repo) }

      it 'updates connections from branch name and body' do
        pull_request.remote_head_branch = "bug/##{new_branch_ticket.remote_number}-test"
        pull_request.remote_body += "\nConnects ##{new_body_ticket.remote_number}"

        expect {
          pull_request.save!
        }.to change {
          connection_counts
        }.to(new_branch_ticket => 1, body_ticket => 1, new_body_ticket => 1)
      end
    end
  end
end
