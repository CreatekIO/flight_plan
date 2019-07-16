require 'rails_helper'

RSpec.describe IssueNumberExtractor do
  describe '.from_branch' do
    it 'matches numbers with an octothorpe' do
      expect(described_class.from_branch('feature/#123-test')).to eq('123')
    end

    it 'ignores numbers without an octothorpe' do
      expect(described_class.from_branch('feature/123-test')).to be_nil
    end

    it 'ignores octothorpe-prefixed non-numbers' do
      aggregate_failures do
        expect(described_class.from_branch('feature/#test')).to be_nil
        expect(described_class.from_branch('feature/#')).to be_nil
      end
    end

    context 'with multiple matches' do
      it 'returns only the first match' do
        expect(described_class.from_branch('#123-test-#999')).to eq('123')
      end
    end
  end

  describe '.connections' do
    let(:repo) { double(:repo, remote_url: 'a-user/a-repo') }

    let(:expected) do
      nums = %w[1 10 21 32 43 54]

      [
        *nums.map { |n| { repo: repo.remote_url, number: n } },
        *nums.map { |n| { repo: 'another/repo_name', number: n } }
      ]
    end

    it 'finds numbers prefixed with forms of "connect"' do
      text = <<-TEXT.strip_heredoc
        Connect #1
        connect #10
        Connects #21
        connects #32
        Connected #43
        connected #54

        Connect another/repo_name#1
        connect another/repo_name#10
        Connects another/repo_name#21
        connects another/repo_name#32
        Connected another/repo_name#43
        connected another/repo_name#54
      TEXT

      expect(described_class.connections(text, current_repo: repo)).to match_array(
        expected
      )
    end

    it 'finds numbers prefixed with forms of "connect to"' do
      text = <<-TEXT.strip_heredoc
        Connect to #1
        connect to #10
        Connects to #21
        connects to #32
        Connected to #43
        connected to #54

        Connect to another/repo_name#1
        connect to another/repo_name#10
        Connects to another/repo_name#21
        connects to another/repo_name#32
        Connected to another/repo_name#43
        connected to another/repo_name#54
      TEXT

      expect(described_class.connections(text, current_repo: repo)).to match_array(
        expected
      )
    end

    it 'handles nil' do
      expect(described_class.connections(nil, current_repo: repo).to_a).to eq []
    end
  end
end
