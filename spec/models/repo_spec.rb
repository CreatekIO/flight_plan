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
end
