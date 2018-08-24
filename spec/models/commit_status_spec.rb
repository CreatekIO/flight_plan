require 'rails_helper'

RSpec.describe CommitStatus, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
  end

  describe '.import' do
    let(:payload) { webhook_payload(:status) }
    let(:repo) { create(:repo) }

    subject(:commit_status) { described_class.import(payload, repo) }

    it 'imports status details correctly' do
      expect(commit_status.reload.attributes).to include(
        'remote_id' => payload[:id],
        'repo_id' => repo.id,
        'state' => payload[:state],
        'sha' => payload[:sha],
        'description' => payload[:description],
        'context' => payload[:context],
        'url' => payload[:target_url],
        'author_remote_id' => payload[:commit][:author][:id],
        'author_username' => payload[:commit][:author][:login],
        'committer_remote_id' => payload[:commit][:committer][:id],
        'committer_username' => payload[:commit][:committer][:login],
        'remote_created_at' => Time.zone.parse(payload[:created_at])
      )
    end
  end
end
