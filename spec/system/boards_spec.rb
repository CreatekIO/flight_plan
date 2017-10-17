require 'rails_helper'

RSpec.describe 'boards' do

  let(:board) { create(:board) }
  let!(:swimlanes) { create_list(:swimlane, 3, board: board) }

  it 'shows the swim lanes' do
    visit board_path(board)
    swimlanes.each do |swimlane|
      expect(page).to have_css 'div.header', text: swimlane.name
    end
  end
end
