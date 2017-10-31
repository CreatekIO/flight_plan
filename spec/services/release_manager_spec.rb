require 'rails_helper'
RSpec.describe ReleaseManager, type: :service do
  describe '#cooled_off?' do
    subject{ ReleaseManager.new(board, repo) }
    let(:repo) { create(:repo) }
    let(:ticket) { create(:ticket, repo: repo) }
    let(:board) { create(:board, repos: [ repo ]) }
    let(:deploy_swimlane) { create(:swimlane, board: board) }
    let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: deploy_swimlane) }
    let(:delay) { ReleaseManager::DEPLOY_DELAY }

    before do
      board.update_attributes(deploy_swimlane: deploy_swimlane)
      allow(Time).to receive(:now).and_return(time_now)
    end

    context 'during the working day' do
      let(:time_now) { Time.new(2017, 10, 31, 9, 5) }
      context "when issues were moved to deploy column more than DEPLOY_DELAY minutes ago" do
        before do
          board_ticket.update_attributes(updated_at: time_now - delay)
        end
        it 'returns true' do
          expect(subject.cooled_off?).to eq(true)
        end
      end

      context "when issues were moved in the last DEPLOY_DELAY minutes" do
        before do
          board_ticket.update_attributes(updated_at: (time_now - delay) + 1.second)
        end
        it 'retursn false' do
          expect(subject.cooled_off?).to eq(false)
        end
      end
    end

    context 'outside of the working day' do
      let(:time_now) { Time.new(2017, 10, 31, 8) }
      it 'returns false' do
        expect(subject.cooled_off?).to eq(false)
      end
    end
  end
end
