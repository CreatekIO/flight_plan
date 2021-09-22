require 'rails_helper'

RSpec.describe 'Dragging tickets', js: true do
  include_context 'board with swimlanes'

  before do
    sign_in create(:user)

    stub_gh_get("issues/#{ticket_to_move.number}/labels") do
      [{ id: '111', name: "status: #{source_swimlane.name}", color: '00ff00' }]
    end

    stub_gh_put("issues/#{ticket_to_move.number}/labels")
  end

  let!(:tickets) do
    board.swimlanes.flat_map do |swimlane|
      Array.new(2) do
        create(:ticket, repo: repo).tap do |ticket|
          create(:board_ticket, board: board, ticket: ticket, swimlane: swimlane)
        end
      end
    end
  end

  let(:ticket_to_move) { tickets.first }
  let(:board_ticket) { ticket_to_move.board_tickets.first }
  let(:source_swimlane) { board.swimlanes.first }
  let(:destination_swimlane) { board.swimlanes.second }

  def within_swimlane(swimlane, &block)
    within(
      %{[data-rbd-droppable-id="Swimlane/swimlane##{swimlane.id}"]},
      &block
    )
  end

  it 'allows dragging between swimlanes' do
    visit board_path(board)

    within_swimlane(source_swimlane) do
      expect(page).to have_css(
        '[data-rbd-draggable-id]:nth-child(1)',
        text: ticket_to_move.title
      )
    end

    within_swimlane(destination_swimlane) do
      expect(page).not_to have_text(ticket_to_move.title)
    end

    # This is how react-beautiful-dnd does it in their own Cypress tests
    # - my guess would be that dragging via mouse is too complicated
    find(%{[data-rbd-drag-handle-draggable-id="TicketCard/boardTicket##{board_ticket.id}"]})
      .native
      .node
      .focus
      .type(:Space, :Right, :Down, :Space)

    # Ticket moves immediately...
    within_swimlane(source_swimlane) do
      expect(page).not_to have_text(ticket_to_move.title)
    end

    within_swimlane(destination_swimlane) do
      expect(page).to have_css(
        '[data-rbd-draggable-id]:nth-child(2)',
        text: ticket_to_move.title
      )
    end

    page.driver.wait_for_network_idle

    # ...and isn't reverted back...
    within_swimlane(source_swimlane) do
      expect(page).not_to have_text(ticket_to_move.title)
    end

    within_swimlane(destination_swimlane) do
      expect(page).to have_css(
        '[data-rbd-draggable-id]:nth-child(2)',
        text: ticket_to_move.title
      )
    end

    refresh
    page.driver.wait_for_reload

    # ...and changes are saved in the database
    within_swimlane(source_swimlane) do
      expect(page).not_to have_text(ticket_to_move.title)
    end

    within_swimlane(destination_swimlane) do
      expect(page).to have_css(
        '[data-rbd-draggable-id]:nth-child(2)',
        text: ticket_to_move.title
      )
    end
  end
end
