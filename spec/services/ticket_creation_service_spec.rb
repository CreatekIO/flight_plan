require 'rails_helper'

RSpec.describe TicketCreationService do
  describe '.create_ticket' do
    let!(:board_repo) { create(:board_repo, repo: repo, board: board) }
    let(:board) { create(:board) }
    let!(:swimlane) { create(:swimlane, board: board) }
    let(:repo) { create(:repo) }
    let(:attributes) do
      {
        title: 'A new ticket',
        description: 'This is a new ticket',
        repo_id: board_repo.id
      }
    end
    let(:remote_ticket) do
      { remote_id: -1 }
    end

    it 'creates a new github ticket' do
      allow(Octokit).to receive(:create_issue).and_return(remote_ticket)
      expect { described_class.new(attributes).create_ticket! }.to change { repo.tickets.count }.by(1)
    end
  end
end
