require 'rails_helper'

RSpec.describe 'boards', skip: 'needs JS features tests set-up' do
  let(:board) { create(:board) }
  let!(:swimlanes) { create_list(:swimlane, 3, board: board) }
  let(:user) { create(:user) }

  it 'shows the swim lanes' do
    login_as(user, scope: :user)
    visit board_path(board)
    swimlanes.each do |swimlane|
      expect(page).to have_css 'div.header', text: swimlane.name
    end
  end
end
