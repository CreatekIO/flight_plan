require 'rails_helper'

RSpec.describe BoardTicket, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:swimlane) }
  end
end
