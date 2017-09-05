require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to have_many(:comments) }
  end

  describe '#save' do
    subject { create(:ticket, remote_number: '4') }

    before(:each) do
      subject # force creation of subject in database
    end

    context 'when an issue is moved to "Closed"' do
      subject { create(:ticket, state: 'Lobby', remote_number: '4') }

      it 'updates the GitHub issue via the API' do
        stub = stub_request(:patch, "https://api.github.com/repos/createkio/flight_plan/issues/4").
          with(body: "{\"state\":\"closed\"}")
        subject.state = 'Closed'
        subject.save

        expect(stub).to have_been_requested
      end
    end

    context 'when an issue is moved from "Closed"' do
      subject { create(:ticket, state: 'Closed', remote_number: '4') }

      it 'updates the GitHub issue via the API' do
        stub = stub_request(:patch, "https://api.github.com/repos/createkio/flight_plan/issues/4").
          with(body: "{\"state\":\"open\"}")
        subject.state = 'Lobby'
        subject.save

        expect(stub).to have_been_requested
      end
    end
  end

  context 'with no state change' do
    it 'doesn\'t create/update any new timesheets' do
      expect{ subject.update_attributes(remote_number: '5') }.to_not change{ Timesheet.count }
    end
  end

  context 'when state changes' do
    subject { create(:ticket, state: 'Backlog') }

    it 'creates a new open timesheet' do
      expect {
        subject.update_attributes(state: 'Development')
      }.to change {
        subject.timesheets.where(state: 'Development', before_state: 'Backlog', ended_at: nil, after_state: nil).count
      }
    end

    it 'closes the open timesheet' do
      expect {
        subject.update_attributes(state: 'Development')
      }.to change {
        subject.reload.open_timesheet.id
      }
    end
  end
end
