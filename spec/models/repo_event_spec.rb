require 'rails_helper'

RSpec.describe RepoEvent, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to belong_to(:user).with_primary_key(:uid) }
    it { is_expected.to belong_to(:record) }
  end
end
