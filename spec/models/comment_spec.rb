require 'rails_helper'

RSpec.describe Comment do
  describe 'associations' do
    it { is_expected.to belong_to(:ticket) }
  end
end
