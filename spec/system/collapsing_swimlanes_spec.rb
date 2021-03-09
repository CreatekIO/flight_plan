require 'rails_helper'

RSpec.describe 'Collapsing swimlanes', js: true do
  include_context 'board with swimlanes'

  before do
    Flipper.enable(:v2_ui)
    sign_in create(:user)
  end

  let!(:ticket) do
    create(:ticket, repo: repo).tap do |ticket|
      create(:board_ticket, board: board, ticket: ticket, swimlane: dev)
    end
  end

  def toggle_swimlane(swimlane)
    find(
      :xpath,
      %{.//*[contains(text(), "#{swimlane.name}")]/following-sibling::button}
    ).click
  end

  it 'allows swimlanes to be collapsed and expanded' do
    visit board_path(board)
    expect(page).to have_text(ticket.title)

    toggle_swimlane(dev)
    expect(page).to_not have_text(ticket.title)

    refresh
    page.driver.wait_for_reload
    expect(page).to_not have_text(ticket.title)

    toggle_swimlane(dev)
    expect(page).to have_text(ticket.title)
  end
end
