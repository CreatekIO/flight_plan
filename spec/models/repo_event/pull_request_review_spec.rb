require 'rails_helper'

RSpec.describe RepoEvent::PullRequestReview do
  describe ".import" do
    let(:payload) { webhook_payload(:pull_request_review) }
    let(:repo) { create(:repo) }

    let!(:pull_request) do
      create(:pull_request, repo: repo, remote_number: payload[:pull_request][:number])
    end

    subject(:repo_event) { described_class.import(payload, repo) }

    it 'imports base details correctly' do
      expect(repo_event.reload.attributes).to include(
        'repo_id' => repo.id,
        'remote_user_id' => payload[:sender][:id].to_s,
        'remote_username' => 'baxterthehacker'
      )
    end

    it 'imports review details correctly' do
      expect(repo_event.reload.attributes).to include(
        'remote_id' => payload[:review][:id].to_s,
        'action' => 'submitted',
        'state' => 'approved',
        'branch' => payload[:pull_request][:head][:ref],
        'sha' => payload[:pull_request][:head][:sha],
        'url' => payload[:review][:html_url]
      )
    end

    it 'links to referenced pull_request' do
      expect(repo_event.reload.record).to eq(pull_request)
    end
  end
end
