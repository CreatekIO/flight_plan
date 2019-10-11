require 'rails_helper'

RSpec.describe BoardChannel do
  let(:user) { build_stubbed(:user) }
  let(:board) { create(:board) }

  before do
    stub_connection current_user: user
  end

  context 'with id set' do
    it 'streams from board with id' do
      subscribe id: board.id

      aggregate_failures do
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(board)
      end
    end
  end

  context 'with no id set' do
    it 'rejects subscription' do
      subscribe

      expect(subscription).to be_rejected
    end
  end
end
