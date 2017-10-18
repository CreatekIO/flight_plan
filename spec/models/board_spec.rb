require 'rails_helper'

RSpec.describe Board, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:board_repos) }
    it { is_expected.to have_many(:repos).through(:board_repos) }
    it { is_expected.to have_many(:swimlanes) }
    it { is_expected.to have_many(:board_tickets) }
  end

  describe '#open_swimlane' do
    include_context 'board with swimlanes'
    it 'returns the first swimlane' do
      expect(board.open_swimlane).to eq(backlog)
    end
  end

  describe '#closed_swimlane' do
    include_context 'board with swimlanes'
    it 'returns the last swimlane' do
      expect(board.closed_swimlane).to eq(closed)
    end
  end
end
