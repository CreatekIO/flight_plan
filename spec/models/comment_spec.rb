require 'rails_helper'

RSpec.describe Comment do
  describe 'associations' do
    it { is_expected.to belong_to(:ticket) }
  end

  describe '.import' do
    include_context 'remote issue'

    subject { described_class.import(remote_comment, repo, remote_issue: remote_issue) }

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
      it 'creates a new comment for the issue' do
        expect {
          subject
        }.to change { Comment.count }.by(1)
      end
    end

    context 'when the comment already exists' do
      let(:ticket) { create(:ticket, repo: repo) }

      it 'updates the comment' do
        comment = create(:comment, remote_body: 'before text', remote_id: comment_id, ticket: ticket)

        expect {
          subject
        }.not_to change { Comment.count }

        expect(comment.reload.remote_body).to eq('text')
      end
    end
  end
end
