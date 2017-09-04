require 'rails_helper'

RSpec.describe 'boards' do
  it 'shows the swim lanes' do
    visit root_path
    expect(page).to have_css :h3, text: 'Lobby'
    expect(page).to have_css :h3, text: 'Backlog'
    expect(page).to have_css :h3, text: 'Development'
    expect(page).to have_css :h3, text: 'Demo'
    expect(page).to have_css :h3, text: 'Code Review'
    expect(page).to have_css :h3, text: 'Acceptance'
    expect(page).to have_css :h3, text: 'Acceptance - Done'
    expect(page).to have_css :h3, text: 'Deploying'
    expect(page).to have_css :h3, text: 'Closed'
  end
end
