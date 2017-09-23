require 'rails_helper'

RSpec.describe Board, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:board_repos) }
    it { is_expected.to have_many(:repos).through(:board_repos) }
    it { is_expected.to have_many(:swimlanes) }
  end
end
