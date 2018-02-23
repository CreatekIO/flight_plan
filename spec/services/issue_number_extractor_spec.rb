require 'rails_helper'

RSpec.describe IssueNumberExtractor do
  describe '.from_branch' do
    it 'matches numbers with an octothorpe' do
      expect(described_class.from_branch('feature/#123-test')).to eq('123')
    end

    it 'ignores numbers without an octothorpe' do
      expect(described_class.from_branch('feature/123-test')).to be_nil
    end

    context 'with multiple matches' do
      it 'returns only the first match' do
        expect(described_class.from_branch('#123-test-#999')).to eq('123')
      end
    end
  end

  describe '.connections' do
    it 'finds numbers prefixed with forms of "connect"' do
      text = <<-TEXT.strip_heredoc
        Connect #1
        connect #10
        Connects #21
        connects #32
        Connected #43
        connected #54
      TEXT

      expect(described_class.connections(text)).to match_array(
        %w(1 10 21 32 43 54)
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
      TEXT

      expect(described_class.connections(text)).to match_array(
        %w(1 10 21 32 43 54)
      )
    end

    it 'handles nil' do
      expect(described_class.connections(nil)).to eq []
    end
  end
end
