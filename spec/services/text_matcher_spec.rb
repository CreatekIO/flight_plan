require 'rails_helper'

RSpec.describe TextMatcher do
  describe '#filter' do
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
    let(:result) { described_class.from(regex).filter(branch_names) }

    context 'when given nil as matcher' do
      let(:regex) { nil }

      it 'returns empty array' do
        expect(result).to be_empty
      end
    end

    context 'when given empty string as matcher' do
      let(:regex) { '' }

      it 'returns empty array' do
        expect(result).to be_empty
      end
    end

    context 'when given a literal string' do
      let(:regex) { /^l10n_develop$/ }

      it 'returns just that branch' do
        expect(result).to contain_exactly('l10n_develop')
      end
    end

    context 'when it matches more than one string' do
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
end
