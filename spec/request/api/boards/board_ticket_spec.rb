require 'rails_helper'

RSpec.describe 'BoardTickets', type: :request do
  include_context 'api'
  let(:path) { "/api/boards/#{board.id}/board_tickets" }
  let(:board) { create(:board) }
  let(:repo) { create(:repo) }
  let(:ticket_1) { create(:ticket, repo: repo) }
  let(:ticket_2) { create(:ticket, repo: repo) }
  let(:swimlane) { create(:swimlane, board: board) }
  let!(:board_ticket_1) { create(:board_ticket, board: board, ticket: ticket_1, swimlane: swimlane) }
  let!(:board_ticket_2) { create(:board_ticket, board: board, ticket: ticket_2, swimlane: swimlane) }

  it 'lists all board tickets' do
    get path, headers: api_headers

    expect(response).to have_http_status(:ok)
    expect(json.length).to eq(2)
  end
end
