require 'rails_helper'

RSpec.describe BoardTicket, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:swimlane) }
    it { is_expected.to have_many(:timesheets) }
    it { is_expected.to have_one(:open_timesheet) }
  end

  describe '#save' do
    include_context 'board with swimlanes'

    let(:ticket) { create(:ticket, remote_number: '4', repo: repo) }
    subject { create(:board_ticket, board: board, ticket: ticket, swimlane: backlog) }

    before(:each) do
      subject # force creation of subject in database
    end

    context 'when an issue is moved to "Closed"' do
      it 'updates the GitHub issue via the API' do
        stub = stub_request(:patch, "https://api.github.com/repos/#{remote_url}/issues/4").
          with(body: "{\"state\":\"closed\"}")
        subject.swimlane = closed
        subject.save

        expect(stub).to have_been_requested
      end
    end

    context 'when an issue is moved from "Closed"' do
      subject { create(:board_ticket, swimlane: closed, ticket: ticket, board: board) }

      it 'updates the GitHub issue via the API' do
        stub = stub_request(:patch, "https://api.github.com/repos/#{remote_url}/issues/4").
          with(body: "{\"state\":\"open\"}")
        subject.swimlane = backlog
        subject.save

        expect(stub).to have_been_requested
      end
    end

    context 'with no state change' do
      it 'doesn\'t create/update any new timesheets' do
        expect{ subject.touch }.to_not change{ Timesheet.count }
      end
    end

    context 'when state changes' do
      subject { create(:board_ticket, swimlane: backlog, ticket: ticket, board: board) }

      it 'creates a new open timesheet' do
        expect {
          subject.update_attributes(swimlane_id: dev.id)
        }.to change {
          subject.timesheets.where(swimlane_id: dev.id, before_swimlane_id: backlog.id, ended_at: nil, after_swimlane_id: nil).count
        }
      end

      it 'closes the open timesheet' do
        expect {
          subject.update_attributes(swimlane_id: dev.id)
        }.to change {
          subject.reload.open_timesheet.id
        }
      end

      it 'changes labels on the remote' do
        stub = stub_request(:put, "https://api.github.com/repos/#{remote_url}/issues/4/labels").
          with(body: "[\"status: dev\"]")
        subject.swimlane = dev
        subject.save

        expect(stub).to have_been_requested
      end
    end
  end
end
