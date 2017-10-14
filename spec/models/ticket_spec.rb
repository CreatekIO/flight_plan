require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:board_tickets) }
  end

  describe '.import_for_remote' do
    include_context 'board with swimlanes'
    let(:issue_id) { 888 }
    let(:issue_json) {
      { id: issue_id,
        number: 100,
        title: 'issue title',
        body: 'issue body',
        state: 'open',
        labels: [
          {
            name: 'status: dev'
          }
        ]
      }
    }

    let(:repo_json) {
      {
        full_name: remote_url
      }
    }

    context 'when the ticket does not already exist' do
      it 'adds the issue to the repo' do
        expect {
          described_class.import_from_remote(issue_json, repo_json)
        }.to change { repo.tickets.count }.by(1)
      end
    end

    context 'when the tickets exists' do
      it 'updates the ticket' do
        ticket = create(:ticket, remote_title: 'before title', repo: repo, remote_id: issue_id)
        expect {
          described_class.import_from_remote(issue_json, repo_json)
        }.not_to change { repo.tickets.count }
        expect(ticket.reload.remote_title).to eq('issue title')
      end
    end

  end
end
