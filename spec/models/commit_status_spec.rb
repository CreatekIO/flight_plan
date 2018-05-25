require 'rails_helper'

RSpec.describe CommitStatus, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
  end
end
