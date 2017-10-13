require 'rails_helper'

RSpec.describe SwimlaneTransition, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:swimlane) }
    it { is_expected.to belong_to(:transition).class_name('Swimlane') }
  end
end
