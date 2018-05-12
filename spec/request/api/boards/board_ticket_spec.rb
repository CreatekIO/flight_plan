require 'rails_helper'

RSpec.describe 'BoardRickets API', type: :request do
  let(:path) { "/api/boards/#{board.id}/board_tickets" }
  let(:params) { nil }
  let(:headers) {
    {
      'Authorization' => 'Token token=key:secret',
      'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json'
    }
  }
  let(:board) { create(:board) }
  let(:repo) { create(:repo) }
  let(:ticket) { create(:ticket, repo: repo) }
  let(:swimlane) { create(:swimlane, board: board) }
  let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: swimlane) }

  it 'lists all board tickets' do
      get path, headers: headers

      json = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)

      expect(json.length).to eq(1)
  end
end
