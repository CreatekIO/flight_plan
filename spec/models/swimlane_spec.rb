require 'rails_helper'

RSpec.describe Swimlane, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to have_many(:board_tickets) }
    it { is_expected.to have_many(:tickets).through(:board_tickets) }
    it { is_expected.to have_many(:swimlane_transitions) }
    it { is_expected.to have_many(:transitions).through(:swimlane_transitions) }
  end

  describe '.find_by_label!' do
    let(:board) { create(:board) }
    let!(:swimlane) { create(:swimlane, board: board, name: 'Backlog') }

    it 'finds matching swimlane, regardless of case' do
      labels = [
        swimlane.name,
        swimlane.name.downcase,
        swimlane.name.upcase,
        "status: #{swimlane.name.downcase}"
      ]

      expect(
        labels.map { |label| board.swimlanes.find_by_label!(label) }
      ).to all eq(swimlane)
    end
  end
end
