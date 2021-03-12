require 'rails_helper'

RSpec.describe 'Realtime updates', js: true do
  include_context 'board with swimlanes'

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    Flipper.enable(:v2_ui)
    Flipper.enable(:realtime_updates)
  end

  def broadcast_move(by:, to:, position:)
    request = ActionDispatch::Request.new({})
    request.routes = TicketMovesController._routes

    instance = TicketMovesController.new
    instance.set_request!(request)
    instance.set_response!(TicketMovesController.make_response!(request))
    instance.instance_variable_set(:@board, board)

    template = JbuilderTemplate.new(instance.view_context) do |json|
      json.type 'ws/TICKET_WAS_MOVED'

      json.payload do
        json.boardTicket do
          json.partial! board_ticket, swimlane: to
        end

        json.destinationId to.id
        json.destinationIndex position
      end

      json.meta { json.userId(by.id) }
    end

    BoardChannel.broadcast_to(board, template.attributes!)
  end

  def wait_for_subscription(user)
    start_time = Capybara::Helpers.monotonic_time

    begin
      ActionCable.server.pubsub
        .send(:subscriber_map)
        .instance_variable_get(:@subscribers)
        .fetch("action_cable/#{user.to_gid_param}")
    rescue KeyError
      raise if (Capybara::Helpers.monotonic_time - start_time) >= Capybara.default_max_wait_time

      sleep(0.05)
      retry
    end
  end

  let!(:ticket) { create(:ticket, repo: repo) }
  let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: backlog) }

  def within_swimlane(swimlane, &block)
    within(
      %{[data-rbd-droppable-id="Swimlane/swimlane##{swimlane.id}"]},
      &block
    )
  end

  context 'ticket moved by another user' do
    it 'moves ticket for user' do
      sign_in user
      visit board_path(board)

      within_swimlane(backlog) do
        expect(page).to have_text(ticket.title)
      end

      within_swimlane(dev) do
        expect(page).not_to have_text(ticket.title)
      end

      wait_for_subscription user

      broadcast_move(by: other_user, to: dev, position: 0)

      within_swimlane(backlog) do
        expect(page).not_to have_text(ticket.title)
      end

      within_swimlane(dev) do
        expect(page).to have_text(ticket.title)
      end
    end
  end
end
