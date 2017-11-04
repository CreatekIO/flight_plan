require 'rails_helper'

RSpec.describe Repo, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:boards).through(:board_repos) }
    it { is_expected.to have_many(:tickets) }
    it { is_expected.to have_many(:board_repos) }
  end

  subject { create(:repo) }

  describe '#branch_names' do
    let(:branches) { 
      [ 
        { name: 'develop' },
        { name: 'master' },
        { name: 'feature/#1-fix-me' }
      ]
    }
    it 'returns the names of all the branches on a repo' do
      stub = stub_request(:get, "https://api.github.com/repos/user/repo_name/branches?per_page=100")
        .to_return(status: 200, body: branches)

      expect(subject.branch_names).to include('master', 'develop', 'feature/#1-fix-me')
      expect(stub).to have_been_requested.once
    end
  end

  describe '#compare' do
    it 'returns the diff between two branches' do
      stub = stub_request(:get, "https://api.github.com/repos/user/repo_name/compare/develop...master")
      subject.compare('develop', 'master')
      expect(stub).to have_been_requested.once
    end 
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
