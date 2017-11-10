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

  describe '#regex_branches' do
    let(:branch_names) {
      %w( 
         develop 
         master 
         feature/#123-test 
         feature/#456-test-2 
         config_changes 
         l10n_develop 
      ) 
    }
    let(:regex) { raise NotImplementedError }
    let(:result) { subject.regex_branches(regex ) }
 
    before do
      allow(subject).to receive(:branch_names).and_return(branch_names)
    end
    context 'when it\'s a literal string' do
      let(:regex) { /^l10n_develop$/ }
      it 'returns just that branch' do
        expect(result).to contain_exactly('l10n_develop')
      end
    end

    context 'when it matches more than one branch name' do
      let(:regex) { /^l10n_develop|config_changes$/ }
      it 'returns the matching branches' do
        expect(result).to contain_exactly('l10n_develop', 'config_changes')
      end
    end

    context 'when it matches a wildcard' do
      let(:regex) { /^feature\/#[0-9]*-/ }
      it 'returns the matching branches' do
        expect(result).to contain_exactly('feature/#123-test', 'feature/#456-test-2')
      end
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
    it 'returns pull request details' do
      stub = stub_request(:get, "https://api.github.com/repos/user/repo_name/pulls?per_page=100")
      subject.pull_requests

      expect(stub).to have_been_requested.once
    end
  end

  describe '#create_pull_request' do
    let(:title) { 'Pull Request Name' }
    let(:body) { 'Body text' }
    let(:base) { 'master' }
    let(:head) { 'branch-to-be-merged ' }
    let(:params) { 
      {
        base: base,
        head: head,
        title: title,
        body: body
      }
    }
    it 'creates a pull requests' do
      stub = stub_request(:post, "https://api.github.com/repos/user/repo_name/pulls").with(body: params)
      subject.create_pull_request(base, head, title, body)

      expect(stub).to have_been_requested.once
    end
  end

  describe '#create_ref' do
    let(:branch_name) { 'release/123' }
    let(:sha) { '5g32345676a44545' }
    let(:params) {  
      {
        ref: "refs/#{branch_name}",
        sha: sha,
      }
    }
    it 'create a branch on github' do
      stub = stub_request(:post, "https://api.github.com/repos/user/repo_name/git/refs").
        with(body: params)
      subject.create_ref(branch_name, sha)

      expect(stub).to have_been_requested.once
    end
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
