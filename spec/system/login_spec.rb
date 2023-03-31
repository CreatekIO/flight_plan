require 'rails_helper'

RSpec.describe 'User logging in via GitHub', js: true do
  let(:board) { create(:board, repos: [repo]) }
  let(:repo) { create(:repo) }
  let(:swimlane) { create(:swimlane, board: board) }

  before do
    create(
      :board_ticket,
      board: board,
      ticket: create(:ticket, repo: repo),
      swimlane: swimlane
    )
  end

  it 'allows user to login and redirects to first board' do
    user = build(:user)
    stub_omniauth user: user, token: generate(:github_oauth_token)

    visit '/'
    click_on 'Sign in with GitHub'

    expect(page).to have_text(board.name)
    expect(page).to have_css(%{img[src*="#{user.username}.png"]})
  end

  context 'with a repo that uses GH app' do
    let(:user) { create(:user) }

    before do
      repo_using_app = create(:repo, :uses_app)

      create(
        :board_ticket,
        board: board,
        ticket: create(:ticket, repo: repo_using_app),
        swimlane: swimlane
      )
      board.repos << repo_using_app

      stub_omniauth user: user, token: generate(:github_app_token)

      sign_in user, github_token: github_token_type
    end

    context 'no app token in session' do
      let(:github_token_type) { :oauth }

      it 'renders warning with login button' do
        visit board_path(board)

        expect(page).to have_text(/dragging needs\sgithub app/i)

        click_on 'GitHub App login'

        expect(page).to have_current_path(board_path(board)).and have_css('#react_board')
        expect(page).not_to have_text(/dragging needs\sgithub app/i)
      end
    end

    context 'with app token in session' do
      let(:github_token_type) { :both }

      it 'renders board' do
        visit board_path(board)

        expect(page).to have_current_path(board_path(board)).and have_css('#react_board')
        expect(page).not_to have_text(/dragging needs\sgithub app/i)
      end
    end
  end
end
