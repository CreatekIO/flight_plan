require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to have_many(:comments) }
  end

  describe '#save' do
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
end
