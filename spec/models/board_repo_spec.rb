require 'rails_helper'

RSpec.describe BoardRepo, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to belong_to(:board) }
  end
end
