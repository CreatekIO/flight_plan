require 'rails_helper'

RSpec.describe Comment do
  describe 'associations' do
    it { is_expected.to belong_to(:ticket) }
  end

  describe '.import' do
    pending 'importing a comment'
  end

  describe '.find_by_remote' do
    pending 'find or create comment using remote id'
  end
end
