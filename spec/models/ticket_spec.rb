require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to have_many(:comments) }
  end
end
