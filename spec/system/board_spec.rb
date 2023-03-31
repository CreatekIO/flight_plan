require 'rails_helper'

RSpec.describe 'Viewing board', js: true do
  include_context 'board with swimlanes'

  before do
    sign_in user, github_token: true
  end

  let(:user) { create(:user) }

  let!(:board_tickets) do
    board.swimlanes.map do |swimlane|
      create(
        :board_ticket,
        board: board,
        ticket: create(:ticket, repo: repo),
        swimlane: swimlane
      )
    end
  end

  let(:ticket) { board_tickets.first.ticket }
  let!(:labels) { create_pair(:label, repo: repo) }
  let!(:milestone) { create(:milestone, repo: repo) }
  let!(:assignments) { create_pair(:ticket_assignment, ticket: ticket) }

  before do
    ticket.labels = labels
    ticket.milestone = milestone

    ticket.save!
  end

  it 'loads tickets in their swimlanes' do
    visit board_path(board)

    expect(page).to have_text(board.name)

    board.swimlanes.each do |swimlane|
      expect(page).to have_text(swimlane.name)

      within(%{[data-rbd-droppable-id="Swimlane/swimlane##{swimlane.id}"]}) do
        expect(page).to have_css(%{[data-rbd-draggable-id^="TicketCard"]})
      end
    end

    within(first("[data-rbd-draggable-id]")) do
      expect(page).to have_link(href: ticket.html_url)
      expect(page).to have_link(href: client_side_board_path(board, "#{repo.slug}/#{ticket.number}"))

      expect(page).to have_text(milestone.title)

      labels.map(&:name).each do |label_name|
        expect(page).to have_text(label_name)
      end

      assignments.map(&:assignee_username).each do |username|
        expect(page).to have_css(%{img[src*="#{username}.png"]})
      end
    end
  end
end
