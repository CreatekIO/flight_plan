require 'rails_helper'

RSpec.describe 'BoardTickets', type: :request do
  include_context 'api'
  let(:path) { "/boards/#{board.id}/board_tickets" }
  let(:board) { create(:board) }
  let(:repo) { create(:repo) }
  let(:slug) { repo.slug }
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

    let!(:issue_request) do
      params = hash_including(
        title: ticket_params[:ticket][:title],
        body: ticket_params[:ticket][:description]
      )

      stub_gh_post('issues', params) { remote_ticket }
    end

    it 'creates a board_ticket' do
      aggregate_failures do
        expect {
          post path, params: ticket_params, headers: api_headers
        }.to change { board.board_tickets.count }.by(1)
          .and change { repo.tickets.count }.by(1)

        expect(issue_request).to have_been_requested
      end
    end
  end
end
