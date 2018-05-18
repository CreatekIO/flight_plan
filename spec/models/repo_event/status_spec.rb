require 'rails_helper'

RSpec.describe RepoEvent::Status do
  describe ".import" do
    let(:payload) { webhook_payload(:status) }
    let(:repo) { create(:repo) }

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
        'remote_id' => payload[:id].to_s,
        'action' => 'changed',
        'state' => payload[:state],
        'branch' => payload[:branches].first[:name],
        'sha' => payload[:sha],
        'url' => payload[:target_url],
        'context' => payload[:context]
      )
    end
  end
end
