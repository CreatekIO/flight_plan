require 'rails_helper'

RSpec.describe 'Paginating tickets', js: true do
  include_context 'board with swimlanes'

  before do
    sign_in create(:user)
  end

  let!(:page_1_tickets) do
    Array.new(10) do
      create(:ticket, repo: repo).tap do |ticket|
        create(:board_ticket, board: board, ticket: ticket, swimlane: dev)
      end
    end
  end

  let!(:page_2_tickets) do
    Array.new(5) do
      create(:ticket, repo: repo).tap do |ticket|
        create(:board_ticket, board: board, ticket: ticket, swimlane: dev)
      end
    end
  end

  it 'allows more tickets to be loaded in a swimlane' do
    visit board_path(board)

    within(%{[data-rbd-droppable-id="Swimlane/swimlane##{dev.id}"]}) do
      page_1_tickets.each do |ticket|
        expect(page).to have_text(ticket.title)
      end

      page_2_tickets.each do |ticket|
        expect(page).not_to have_text(ticket.title)
      end

      click_on 'Load more'

      page_1_tickets.each do |ticket|
        expect(page).to have_text(ticket.title)
      end

      page_2_tickets.each do |ticket|
        expect(page).to have_text(ticket.title)
      end

      expect(page).not_to have_button('Load more')
    end
  end
end
