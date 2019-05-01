require 'rails_helper'

RSpec.describe TicketMovesController do
  describe 'POST #create' do
    include Devise::Test::ControllerHelpers
    include_context 'board with swimlanes'

    let(:ticket) { create(:ticket, repo: repo) }
    let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: backlog) }

    let(:user) { create(:user) }

    before do
      request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in user
    end

    let(:user_token) { "github_token_user_#{user.id}" }

    let(:board_ticket_params) do
      { swimlane_id: destination_swimlane.id, swimlane_position: destination_position }
    end

    subject do
      post(
        :create,
        params: {
          board_id: board, ticket_id: board_ticket, board_ticket: board_ticket_params, format: :json
        },
        session: {
          'warden.user.user.session' => { 'github.token' => user_token }
        }
      )
    end

    let!(:replace_all_labels_call) do
      stub_gh_put("issues/#{ticket.remote_number}/labels")
    end

    before do
      2.times do
        ticket = create(:ticket, repo: repo)
        create(
          :board_ticket,
          board: board,
          ticket: ticket,
          swimlane: destination_swimlane,
          swimlane_position: :last
        )
      end

      stub_gh_get("issues/#{ticket.remote_number}/labels") do
        [
          { id: '111', name: 'type: bug', color: 'ff0000' },
          { id: '112', name: "status: #{backlog.name}", color: '00ff00' }
        ]
      end
    end

    context 'moving within swimlane' do
      let(:destination_swimlane) { backlog }
      let(:destination_position) { 1 }

      it 'moves ticket to new position' do
        aggregate_failures do
          expect {
            subject
          }.to not_change { board_ticket.reload.swimlane }
            .and change { backlog.reload.board_tickets[destination_position] }.to(board_ticket)

          expect(response).to have_http_status(:created)
          expect(replace_all_labels_call).to_not have_been_requested
        end
      end
    end

    context 'moving swimlane' do
      let(:destination_swimlane) { dev }
      let(:destination_position) { 0 }

      it 'moves ticket to new swimlane in correct position' do
        aggregate_failures do
          expect {
            subject
          }.to change { board_ticket.reload.swimlane }.from(backlog).to(dev)
            .and change { dev.reload.board_tickets[destination_position] }.to(board_ticket)

          expect(response).to have_http_status(:created)
          expect(
            replace_all_labels_call.with(
              body: ['type: bug', "status: #{dev.name.downcase}"].to_json,
              headers: { 'Authorization' => "token #{user_token}" }
            )
          ).to have_been_requested
        end
      end
    end
  end
end