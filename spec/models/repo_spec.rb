require 'rails_helper'

RSpec.describe Repo, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:boards).through(:board_repos) }
    it { is_expected.to have_many(:tickets) }
    it { is_expected.to have_many(:board_repos) }
  end

  subject { create(:repo) }
  let(:slug) { subject.slug } # for GitHubApiStubHelper

  describe '.find_by_slug' do
    let!(:repo_with_no_aliases) { create(:repo) }
    let!(:repo_with_1_alias) { create(:repo) }
    let!(:repo_with_many_alias) { create(:repo) }

    let!(:single_alias) { create(:repo_alias, repo: repo_with_1_alias) }
    let!(:multiple_aliases) { create_pair(:repo_alias, repo: repo_with_many_alias) }

    it 'finds repo by `repos.slug`' do
      aggregate_failures do
        expect(
          described_class.find_by_slug(repo_with_no_aliases.slug)
        ).to eq(repo_with_no_aliases)

        expect(
          described_class.find_by_slug(repo_with_1_alias.slug)
        ).to eq(repo_with_1_alias)

        expect(
          described_class.find_by_slug(repo_with_many_alias.slug)
        ).to eq(repo_with_many_alias)
      end
    end

    it 'finds repo by one of its aliases' do
      aggregate_failures do
        expect(
          described_class.find_by_slug(single_alias.slug)
        ).to eq(repo_with_1_alias)

        multiple_aliases.each do |repo_alias|
          expect(
            described_class.find_by_slug(repo_alias.slug)
          ).to eq(repo_with_many_alias)
        end
      end
    end
  end

  describe '#branch_names' do
    let(:branches) do
      [
        { name: 'develop' },
        { name: 'master' },
        { name: 'feature/#1-fix-me' }
      ]
    end

    it 'returns the names of all the branches on a repo' do
      stub = stub_gh_get('branches') { branches }

      expect(subject.branch_names).to include('master', 'develop', 'feature/#1-fix-me')
      expect(stub).to have_been_requested.once
    end
  end

  describe '#regex_branches' do
    let(:branch_names) {
      %w[
         develop
         master
         feature/#123-test
         feature/#456-test-2
         config_changes
         l10n_develop
      ]
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
      stub = stub_gh_get('compare/develop...master')
      subject.compare('develop', 'master')

      expect(stub).to have_been_requested.once
    end
  end

  describe '#pull_requests' do
    it 'returns pull request details' do
      stub = stub_gh_get('pulls')
      subject.pull_requests

      expect(stub).to have_been_requested.once
    end
  end

  describe '#create_pull_request' do
    let(:title) { 'Pull Request Name' }
    let(:body) { 'Body text' }
    let(:base) { 'master' }
    let(:head) { 'branch-to-be-merged ' }

    let(:params) do
      {
        base: base,
        head: head,
        title: title,
        body: body
      }
    end

    it 'creates a pull requests' do
      stub = stub_gh_post('pulls', params)
      subject.create_pull_request(base, head, title, body)

      expect(stub).to have_been_requested.once
    end
  end

  describe '#create_ref' do
    let(:branch_name) { 'release/123' }
    let(:sha) { '5g32345676a44545' }

    let(:params) do
      {
        ref: "refs/#{branch_name}",
        sha: sha,
      }
    end

    it 'create a branch on github' do
      stub = stub_gh_post('git/refs', params)
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
