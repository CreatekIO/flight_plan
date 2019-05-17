require 'rails_helper'

RSpec.describe Comment do
  describe 'associations' do
    it { is_expected.to belong_to(:ticket) }
  end

  describe '.import' do
    include_context 'remote issue'

    subject do
      described_class.import(
        { comment: remote_comment, issue: remote_issue, action: action },
        repo
      )
    end

    let(:comment_id) { 123 }
    let(:remote_comment) {
      {
        id: comment_id,
        body: 'text',
        user: {
          id: 555,
          login: 'jsmith'
        }
      }
    }
    let!(:repo) { create(:repo, remote_url: remote_url) }

    context 'when the comment does not already exist' do
      let(:action) { 'created' }

      it 'creates a new comment for the issue' do
        expect {
          subject
        }.to change { Comment.count }.by(1)
      end
    end

    context 'when the comment already exists' do
      let(:action) { 'edited' }
      let(:ticket) { create(:ticket, repo: repo) }

      it 'updates the comment' do
        comment = create(:comment, remote_body: 'before text', remote_id: comment_id, ticket: ticket)

        expect {
          subject
        }.not_to change { Comment.count }

        expect(comment.reload.remote_body).to eq('text')
      end
    end

    context 'when the comment has been deleted' do
      let(:action) { 'deleted' }
      let(:ticket) { create(:ticket, repo: repo) }
      let!(:comment) { create(:comment, ticket: ticket, remote_id: comment_id) }

      it 'deletes the comment' do
        expect {
          subject
        }.to change { Comment.where(remote_id: comment_id).count }.by(-1)
      end
    end
  end
end
