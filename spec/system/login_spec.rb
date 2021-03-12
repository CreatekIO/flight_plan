require 'rails_helper'

RSpec.describe 'User logging in via GitHub', js: true do
  let(:board) { create(:board, repos: [repo]) }
  let(:repo) { create(:repo) }

  before do
    swimlane = create(:swimlane, board: board)
    ticket = create(:ticket, repo: repo)

    create(
      :board_ticket,
      board: board,
      ticket: ticket,
      swimlane: swimlane
    )

    Flipper.enable(:v2_ui)
  end

  it 'allows user to login and redirects to first board' do
    user = build(:user)
    stub_omniauth user: user

    visit '/'
    click_on 'Sign in with GitHub'

    expect(page).to have_text(board.name)
    expect(page).to have_css(%{img[src*="#{user.username}.png"]})
  end
end
