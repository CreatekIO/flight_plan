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

    let(:number) { '9' }
    let(:ticket) { create(:ticket, number: number, repo: repo) }

    subject { create(:board_ticket, board: board, ticket: ticket, swimlane: backlog) }

    before(:each) do
      subject # force creation of subject in database

      stub_get_issue_labels_request
      stub_put_issue_labels_request

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('DO_NOT_SYNC_TO_GITHUB').and_return(nil)
    end

    context 'when an issue is moved to "Closed"' do
      it 'updates the GitHub issue via the API' do
        stub = stub_request(:patch, "https://api.github.com/repos/#{slug}/issues/#{number}")
          .with(body: { state: 'closed' }.to_json)

        subject.swimlane = closed
        subject.save

        expect(stub).to have_been_requested
      end
    end

    context 'when an issue is moved from "Closed"' do
      subject { create(:board_ticket, swimlane: closed, ticket: ticket, board: board) }

      it 'updates the GitHub issue via the API' do
        stub = stub_request(:patch, "https://api.github.com/repos/#{slug}/issues/#{number}")
          .with(body: { state: 'open' }.to_json)

        subject.swimlane = backlog
        subject.save

        expect(stub).to have_been_requested
      end
    end

    context 'with no state change' do
      it 'doesn\'t create/update any new timesheets' do
        expect { subject.touch }.to_not change { Timesheet.count }
      end
    end

    context 'when state changes' do
      subject { create(:board_ticket, swimlane: backlog, ticket: ticket, board: board) }

      it 'creates a new open timesheet' do
        expect {
          subject.update_attributes(swimlane_id: dev.id)
        }.to change {
          subject.timesheets.where(
            swimlane_id: dev.id,
            before_swimlane_id: backlog.id,
            ended_at: nil,
            after_swimlane_id: nil
          ).count
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
        stub = stub_request(:put, "https://api.github.com/repos/#{slug}/issues/#{number}/labels")
          .with(body: ['status: dev'].to_json)

        subject.swimlane = dev
        subject.save

        expect(stub).to have_been_requested
      end
    end

    context 'moving swimlane' do
      let(:before_swimlane) { backlog }
      let(:after_swimlane) { dev }

      context 'with large numbers of tickets in destination swimlane' do
        let(:bisection_count) { 32 } # we use 32-bit ints

        let!(:board_tickets) do
          (1..(bisection_count + 5)).map do |n|
            before_swimlane.board_tickets.create!(
              board: board,
              ticket: create(:ticket, repo: repo, title: "Ticket #{n}"),
              swimlane_position: :first
            )
          end
        end

        before do
          rebalances = @rebalances = []

          allow(RankedModel::Ranker::Mapper).to receive(:new).with(
            an_instance_of(RankedModel::Ranker),
            an_instance_of(BoardTicket)
          ).and_wrap_original do |new, *args|
            new.call(*args).tap do |mapper|
              allow(mapper).to receive(:rebalance_ranks).and_wrap_original do |rebalance_ranks|
                rebalances << mapper.instance
                rebalance_ranks.call
              end
            end
          end
        end

        it 'doesn\'t raise an error when rebalancing' do
          expect {
            board_tickets.each do |board_ticket|
              board_ticket.update_remote = false
              board_ticket.update_attributes(swimlane: after_swimlane, swimlane_position: :first)
            end
          }.to_not raise_error

          expect(board_tickets.map(&:reload).map(&:swimlane_id)).to all eq(after_swimlane.id)
          expect(@rebalances.count).to be >= 1
        end

        CustomError = Class.new(StandardError)

        it 'rolls back db changes if error arises during save' do
          board_tickets.first(bisection_count).each do |board_ticket|
            board_ticket.update_remote = false
            board_ticket.update_attributes(swimlane: after_swimlane, swimlane_position: :first)
          end

          expect(@rebalances.count).to be_zero

          after_rebalance_tickets = board_tickets.drop(bisection_count)

          after_rebalance_tickets.each do |board_ticket|
            allow(board_ticket).to receive(:save).and_wrap_original do |save, *args|
              save.call(*args)

              raise CustomError
            end

            board_ticket.update_remote = false

            begin
              board_ticket.update_attributes(swimlane: after_swimlane, swimlane_position: :first)
            rescue CustomError
              next
            end
          end

          expect(after_rebalance_tickets.map(&:reload).map(&:swimlane_id)).to all eq(before_swimlane.id)
          expect(@rebalances.count).to eq(after_rebalance_tickets.count)
        end
      end
    end
  end

  describe '#state_durations' do
    pending 'this may changes so not creating a test yet'
  end

  describe '#current_state_duration' do
    pending
  end

  describe '#displayable_durations' do
    pending
  end

  def stub_get_issue_labels_request
    stub_request(:get, "https://api.github.com/repos/#{slug}/issues/#{number}/labels?per_page=100")
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_put_issue_labels_request
    stub_request(
      :put,
      "https://api.github.com/repos/#{slug}/issues/#{number}/labels"
    )
  end
end
