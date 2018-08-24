require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:pull_request_reviews).with_primary_key(:uid) }
  end
end
