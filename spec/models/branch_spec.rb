require 'rails_helper'

RSpec.describe Branch, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to belong_to(:ticket) }
  end

  describe 'attributes' do
    describe 'branch names' do
      it 'strips off prefix when writing branch name' do
        aggregate_failures do
          expect(described_class.new(name: 'refs/heads/master').name).to eq('master')
          expect(described_class.new(base_ref: 'refs/heads/master').base_ref).to eq('master')
        end
      end

      it 'strips off prefix when used in WHERE clause' do
        branch = create(:branch, name: 'develop', base_ref: 'master', repo: create(:repo))

        aggregate_failures do
          expect(described_class.find_by(name: 'refs/heads/develop')).to eq(branch)
          expect(described_class.find_by(name: 'develop')).to eq(branch)

          expect(described_class.find_by(base_ref: 'refs/heads/master')).to eq(branch)
          expect(described_class.find_by(base_ref: 'master')).to eq(branch)
        end
      end
    end
  end

  describe '.import' do
    let(:repo) { create(:repo) }

    subject(:branch) { described_class.import(payload, repo) }

    context 'with new branch' do
      let(:payload) { webhook_payload(:branch_created_push) }

      it 'imports branch with correct attributes' do
        expect(branch.reload.attributes).to include(
          'name' => BranchNameType.normalize(payload[:ref]),
          'base_ref' => BranchNameType.normalize(payload[:base_ref])
        )
      end

      it 'imports HEAD with correct attributes' do
        expect(branch.reload.latest_head.attributes).to include(
          'head_sha' => payload[:after],
          'previous_head_sha' => payload[:before],
          'commits_in_push' => 1,
          'force_push' => false,
          'commit_timestamp' => Time.parse(payload[:head_commit][:timestamp]),
          'author_username' => payload[:head_commit][:author][:username],
          'committer_username' => payload[:head_commit][:committer][:username],
          'pusher_remote_id' => payload[:sender][:id],
          'pusher_username' => payload[:sender][:login]
        )
      end

      it 'creates a new HEAD record' do
        expect {
          subject
        }.to change {
          BranchHead.joins(branch: :repo).where(head_sha: payload[:after], repos: { id: repo }).count
        }.by(1)
      end
    end

    context 'with existing branch' do
      let(:payload) { webhook_payload(:branch_updated_push) }

      let!(:existing_branch) do
        create(:branch, :with_head, repo: repo, name: payload[:ref])
      end

      it 'does\'t create a new branch' do
        expect {
          subject
        }.not_to change(Branch, :count)
      end

      it 'updates #latest_head' do
        expect {
          subject
        }.to change {
          existing_branch.reload.latest_head.head_sha
        }.to(payload[:after])
      end

      context 'and SHA has not been pushed before' do
        it 'creates a new HEAD record' do
          expect {
            subject
          }.to change {
            existing_branch.heads.where(head_sha: payload[:after]).count
          }.from(0).to(1)
        end
      end

      context 'and SHA has been pushed before (force-push)' do
        let!(:existing_head) do
          create(:branch_head, branch: existing_branch, head_sha: payload[:after])
        end

        before do
          payload.merge!(forced: true)
        end

        it 'updates existing HEAD record' do
          expect {
            subject
          }.to change {
            existing_head.reload.slice(:force_push, :updated_at)
          }
        end
      end
    end

    context 'with deleted branch' do
      let(:payload) { webhook_payload(:branch_deleted_push) }

      context 'and the branch exists' do
        before do
          create(:branch, repo: repo, name: payload[:ref])
        end

        it 'deletes corresponding branch on repo' do
          expect {
            subject
          }.to change { repo.branches.where(name: payload[:ref]).count }.by(-1)
        end
      end

      context 'and the branch does\'t exist' do
        it 'does not raise an error' do
          expect {
            subject
          }.not_to raise_error
        end
      end
    end
  end
end
