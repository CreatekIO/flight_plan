require 'rails_helper'

RSpec.describe BranchHead, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:branch) }
  end
end
