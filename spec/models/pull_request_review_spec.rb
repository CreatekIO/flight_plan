require 'rails_helper'

RSpec.describe PullRequestReview, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to belong_to(:pull_request).with_primary_key(:remote_id) }
    it { is_expected.to belong_to(:reviewer).with_primary_key(:uid).conditions(provider: 'github') }
  end
end
