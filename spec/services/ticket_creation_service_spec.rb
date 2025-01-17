require 'rails_helper'

RSpec.describe TicketCreationService do
  describe '.create_ticket' do
    let!(:board_repo) { create(:board_repo, repo: repo, board: board) }
    let(:board) { create(:board) }
    let!(:swimlane) { create(:swimlane, board: board, position: 1) }
    let(:repo) { create(:repo) }
    let(:slug) { repo.slug }
    let(:attributes) do
      {
        title: 'A new ticket',
        description: 'This is a new ticket',
        repo_id: board_repo.id
      }
    end

    let(:remote_ticket) do
      { id: -1, labels: [], assignees: [] }
    end

    let!(:issue_request) do
      params = hash_including(
        title: attributes[:title],
        body: attributes[:description]
      )

      stub_gh_post('issues', params) { remote_ticket }
    end

    it 'creates a new github ticket' do
      aggregate_failures do
        expect {
          described_class.new(attributes).create_ticket!
        }.to change { repo.tickets.count }.by(1)
          .and change { board.board_tickets.count }.by(1)

        expect(issue_request).to have_been_requested
      end
    end

    context 'With specified swimlane' do
      let!(:secondary_swimlane) { create(:swimlane, board: board, position: swimlane.position + 1) }

      let(:attributes) do
        {
          title: 'A new ticket',
          description: 'This is a new ticket',
          repo_id: board_repo.id,
          swimlane: secondary_swimlane.name
        }
      end
      let(:label) do
        create(
          :label,
          repo: repo,
          name: "status: #{secondary_swimlane.name}",
          remote_id: -1
        )
      end
      let(:remote_ticket) do
        {
          id: -1,
          labels: [{ id: label.remote_id, name: label.name}],
          assignees: []
        }
      end

      it 'allows a ticket to be created with a specified swimlane' do
        ticket = described_class.new(attributes).create_ticket!
        expect(ticket.board_tickets.last.swimlane).to eq(secondary_swimlane)
      end
    end
  end
end
