require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:board_tickets) }
  end

  describe '.import' do
    include_context 'board with swimlanes'
    include_context 'remote issue'

    context 'when the ticket does not already exist' do
      it 'adds the issue to the repo' do
        expect {
          described_class.import(remote_issue, remote_repo)
        }.to change { repo.tickets.count }.by(1)
      end
    end

    context 'when the tickets exists' do
      it 'updates the ticket' do
        ticket = create(:ticket, remote_title: 'before title', repo: repo, remote_id: issue_id)
        expect {
          described_class.import(remote_issue, remote_repo)
        }.not_to change { repo.tickets.count }
        expect(ticket.reload.remote_title).to eq('issue title')
      end
    end
  end

  describe '.find_by_remote' do
    let(:remote_issue_id) { 100 }
    let(:remote_issue) { 
      {
        id: remote_issue_id
      }
    }
    let(:remote_repo) { 
      {
        full_name: 'org_name/repo_name'
      }
    }
    let(:repo) { create(:repo) }
    context "when the ticket doesn't exist" do
      it 'creates a new ticket' do
        ticket = described_class.find_by_remote(remote_issue, remote_repo)
        expect(ticket.persisted?).to be(false)
      end
    end
    context "when the ticket exists" do
      it 'finds the ticket' do
        create(:ticket, repo: repo, remote_id: remote_issue_id)
        ticket = described_class.find_by_remote(remote_issue, remote_repo)
        expect(ticket.persisted?).to be(true)
      end
    end
  end

  describe '#update_board_tickets_from_remote' do
    pending
  end
end
