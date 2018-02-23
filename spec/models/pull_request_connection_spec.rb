require 'rails_helper'

RSpec.describe PullRequestConnection, type: :model do
  describe 'associations' do
    it { should belong_to(:pull_request) }
    it { should belong_to(:ticket) }
  end
end
