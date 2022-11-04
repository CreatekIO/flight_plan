require 'rails_helper'

RSpec.describe Board, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:board_repos) }
    it { is_expected.to have_many(:repos).through(:board_repos) }
    it { is_expected.to have_many(:swimlanes) }
    it { is_expected.to have_many(:board_tickets) }
  end

  describe 'validations' do
    def custom_inspect(object, &block)
      object.define_singleton_method(:inspect, &block)
      object
    end

    let(:long_string) do
      custom_inspect("##{'a' * 81}") do
        'a string longer than 80 chars'
      end
    end

    let(:valid_channel) do
      custom_inspect('#testing-channel.name_1') do
        'a string matching `#(letter|number|period|underscore|hyphen)+`'
      end
    end

    let(:channel_without_hash) do
      custom_inspect("#{valid_channel.remove('#')}") do
        'a string not starting with "#"'
      end
    end

    let(:valid_regex) do
      custom_inspect("one|two") { 'a valid regex' }
    end

    let(:invalid_regex) do
      custom_inspect('[a-') { 'an invalid regex' }
    end

    it { should validate_presence_of(:slack_channel) }
    it { should allow_value(valid_channel).for(:slack_channel) }
    it { should_not allow_value(long_string, '#', channel_without_hash).for(:slack_channel) }

    it { should allow_value(nil, '').for(:additional_branches_regex) }
    it { should_not allow_value(invalid_regex).for(:additional_branches_regex) }
  end

  describe '#open_swimlane' do
    include_context 'board with swimlanes'

    it 'returns the first swimlane' do
      expect(board.open_swimlane).to eq(backlog)
    end
  end

  describe '#closed_swimlane' do
    include_context 'board with swimlanes'

    it 'returns the last swimlane' do
      expect(board.closed_swimlane).to eq(closed)
    end
  end
end
