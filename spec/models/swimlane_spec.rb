require 'rails_helper'

RSpec.describe Swimlane, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to have_many(:board_tickets) }
    it { is_expected.to have_many(:tickets).through(:board_tickets) }
    it { is_expected.to have_many(:swimlane_transitions) }
    it { is_expected.to have_many(:transitions).through(:swimlane_transitions) }
  end
end
