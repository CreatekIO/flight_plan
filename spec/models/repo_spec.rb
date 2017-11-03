require 'rails_helper'

RSpec.describe Repo, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:boards).through(:board_repos) }
    it { is_expected.to have_many(:tickets) }
    it { is_expected.to have_many(:board_repos) }
  end

  describe '#branch_names' do
    pending
  end

  describe '#compare' do
    pending
  end

  describe '#pull_requests' do
    pending
  end

  describe '#create_pull_request' do
    pending
  end
  
  describe '#create_ref' do
    pending
  end
  
  describe '#merge' do
    pending
  end

  describe '#refs' do
    pending
  end

  describe '#delete_branch' do
    pending
  end
end
