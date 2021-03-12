require 'rails_helper'

RSpec.describe Timesheet do
  describe 'associations' do
    it { is_expected.to belong_to(:board_ticket) }
    it { is_expected.to belong_to(:swimlane) }
    it { is_expected.to belong_to(:before_swimlane).optional }
    it { is_expected.to belong_to(:after_swimlane).optional }
    it { is_expected.to have_one(:ticket) }
    it { is_expected.to have_one(:board) }
  end
end

