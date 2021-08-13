require 'rails_helper'

RSpec.describe TicketMovesController, type: :request do
  describe 'POST #create' do
    include_context 'board with swimlanes'

    let(:ticket) { create(:ticket, repo: repo) }
    let!(:board_ticket) do
      Timecop.travel(1.day.ago) do # ensure we get an 'old' #started_at on BoardTicket#open_timesheet
        create(:board_ticket, board: board, ticket: ticket, swimlane: backlog)
      end
    end

    let(:user) { create(:user) }

    before do
      sign_in user

      Warden.on_next_request do |proxy|
        proxy.session['github.token'] = user_token
      end
    end

    let(:user_token) { "github_token_user_#{user.id}" }

    let(:board_ticket_params) do
      { swimlane_id: destination_swimlane.id, swimlane_position: destination_position }
    end

    let(:expected_payload) do
      a_hash_including(
        type: 'ws/TICKET_WAS_MOVED',
        payload: {
          boardTicket: a_hash_including(
            id: board_ticket.id,
            url: board_ticket_path(board, board_ticket)
          ),
          destinationId: destination_swimlane.id,
          destinationIndex: destination_position
        },
        meta: {
          userId: user.id
        }
      )
    end

    subject do
      post(
        board_ticket_moves_path(board, board_ticket),
        params: { board_ticket: board_ticket_params }.to_json,
        headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      )
    end

    let!(:get_all_labels_call) do
      stub_gh_get("issues/#{ticket.number}/labels") do
        [
          { id: '111', name: 'type: bug', color: 'ff0000' },
          { id: '112', name: "status: #{backlog.name}", color: '00ff00' }
        ]
      end
    end

    let!(:replace_all_labels_call) do
      stub_gh_put("issues/#{ticket.number}/labels")
    end

    before do
      dev.update_attributes!(display_duration: true)

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

      let(:expected_duration) do
        Time.now.during_business_hours? ? '< 1h' : '1h'
      end

      it 'moves ticket to new swimlane in correct position' do
        aggregate_failures do
          expect {
            subject
          }.to change { board_ticket.reload.swimlane }.from(backlog).to(dev)
            .and change { dev.reload.board_tickets[destination_position] }.to(board_ticket)
            .and have_broadcasted_to([:board, board]).from_channel(BoardChannel).with(expected_payload)

          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)).to include(
            'time_since_last_transition' => expected_duration
          )
          expect(
            replace_all_labels_call.with(
              body: ['type: bug', "status: #{dev.name.downcase}"].to_json,
              headers: { 'Authorization' => "token #{user_token}" }
            )
          ).to have_been_requested
        end
      end

      context 'when unable to perform API calls with given token' do
        let!(:get_all_labels_call_invalid) do
          stub_gh_get("issues/#{ticket.number}/labels", status: 404) do
            { message: 'Not Found' }
          end.with(headers: { 'Authorization' => "token #{user_token}" })
        end

        let!(:replace_all_labels_call_invalid) do
          stub_gh_put("issues/#{ticket.number}/labels", status: 404)
            .with(headers: { 'Authorization' => "token #{user_token}" })
        end

        let(:global_token) { 'github-api-global-token' }

        before do
          allow(Octokit).to receive(:access_token).and_return(global_token)
        end

        it 'retries API calls with global token' do
          aggregate_failures do
            expect {
              subject
            }.to change { board_ticket.reload.swimlane }.from(backlog).to(dev)
              .and change { dev.reload.board_tickets[destination_position] }.to(board_ticket)
              .and have_broadcasted_to([:board, board]).from_channel(BoardChannel).with(expected_payload)

            expect(response).to have_http_status(:created)

            expect(get_all_labels_call_invalid).to have_been_requested
            expect(replace_all_labels_call_invalid).not_to have_been_requested

            expect(
              replace_all_labels_call.with(
                body: ['type: bug', "status: #{dev.name.downcase}"].to_json,
                headers: { 'Authorization' => "token #{global_token}" }
              )
            ).to have_been_requested
          end
        end
      end
    end
  end
end
