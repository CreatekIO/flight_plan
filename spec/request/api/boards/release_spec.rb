require 'rails_helper'

RSpec.describe 'Releases', type: :request do
  include_context 'api'
  let(:path) { "/api/boards/#{board.id}/releases" }
  let(:board) { create(:board) }
  let(:repo) { create(:repo) }
  let(:ticket) { create(:ticket, repo: repo) }
  let(:swimlane) { create(:swimlane, board: board) }
  let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: swimlane) }
  let(:release_params) {
    {
      release: {
        title: 'new release'
      }
    }
  }

  describe 'POST' do
    it 'creates a release' do
      post path, params: release_params, headers: api_headers

      expect(response).to have_http_status(:created)
    end
  end
end
