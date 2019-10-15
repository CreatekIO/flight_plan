require 'rails_helper'

RSpec.describe 'BoardTickets', type: :request do
  include_context 'api'
  let(:path) { "/boards/#{board.id}/board_tickets" }
  let(:board) { create(:board) }
  let(:repo) { create(:repo) }
  let(:board_repo) { create(:board_repo, board: board, repo: repo) }
  let(:ticket_1) { create(:ticket, repo: repo) }
  let(:ticket_2) { create(:ticket, repo: repo) }
  let(:swimlane) { create(:swimlane, board: board) }
  let!(:board_ticket_1) { create(:board_ticket, board: board, ticket: ticket_1, swimlane: swimlane) }
  let!(:board_ticket_2) { create(:board_ticket, board: board, ticket: ticket_2, swimlane: swimlane) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context ':create' do
    let(:ticket_params) do 
      {
        board_id: board.id,
        ticket: {
          title: 'A new ticket',
          description: 'This is a new ticket',
          repo_id: board_repo.id
        }
      } 
    end
    let(:remote_ticket) do
      { remote_id: -1, labels: [], assignees: [] }
    end

    it 'creates a board_ticket' do
      allow(Octokit).to receive(:create_issue).and_return(remote_ticket)

      expect {
        post path, params: ticket_params, headers: api_headers
      }.to change { board.board_tickets.count }.by(1)
    end
  end
end
