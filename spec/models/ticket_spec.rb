require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:board_tickets) }
  end

  describe '.import' do
    include_context 'board with swimlanes'
    include_context 'remote issue'

    let(:subject) { described_class.import(remote_issue, repo) }

    context 'when the ticket does not already exist' do
      it 'adds the issue to the repo' do
        expect {
          @ticket = subject
        }.to change { repo.tickets.count }.by(1)

        aggregate_failures do
          expect(@ticket.title).to eq('issue title')
          expect(@ticket.assignments.pluck(:assignee_remote_id, :assignee_username)).to match_array(
            [assignee.values_at(:uid, :name)]
          )
        end
      end

      context 'when label doesn\'t exist' do
        it 'creates label and labelling' do
          expect {
            @ticket = subject
          }.to change { repo.labels.count }.by(1)

          expect(@ticket.labels.map(&:remote_id)).to eq(remote_issue[:labels].map { |label| label[:id] })
        end
      end

      context 'when label does exist' do
        before do
          Label.import(remote_issue[:labels].first, repo)
        end

        it 'creates labelling but not label' do
          expect {
            @ticket = subject
          }.not_to change(Label, :count)

          expect(@ticket.labels.map(&:remote_id)).to eq(remote_issue[:labels].map { |label| label[:id] })
        end
      end

      context 'when milestone doesn\'t exist' do
        it 'creates milestone' do
          expect {
            @ticket = subject
          }.to change { repo.milestones.count }.by(1)

          expect(@ticket.milestone.remote_id).to be_present.and eq(remote_issue[:milestone][:id])
        end
      end

      context 'when milestone does exist' do
        before do
          Milestone.import(remote_issue[:milestone], repo)
        end

        it 'links ticket to milestone but doesn\'t create milestone' do
          expect {
            @ticket = subject
          }.not_to change(Milestone, :count)

          expect(@ticket.milestone.remote_id).to be_present.and eq(remote_issue[:milestone][:id])
        end
      end

      context 'when no milestone assigned' do
        before do
          remote_issue[:milestone] = nil
        end

        it 'imports ticket' do
          expect {
            @ticket = subject
          }.to change { repo.tickets.count }.by(1)

          expect(@ticket.milestone).to be_nil
        end
      end
    end

    context 'when the ticket exists' do
      let!(:ticket) { create(:ticket, title: 'before title', repo: repo, remote_id: issue_id) }

      it 'updates the ticket' do
        expect {
          @imported_ticket = subject
        }.not_to change { repo.tickets.count }

        expect(@imported_ticket).to eq(ticket)
        expect(ticket.reload.title).to eq(remote_issue[:title])
      end

      context 'when ticket has been reassigned' do
        let!(:ticket_assignments) do
          create_list(:ticket_assignment, 1, ticket: ticket)
        end

        it 'updates the ticket assignments' do
          prior_assignments = ticket_assignments
          @imported_ticket = subject

          prior_assignments.map! do |assignment|
            begin
              assignment.reload
            rescue ActiveRecord::RecordNotFound
              :destroyed
            end
          end

          expect(prior_assignments).to all eq(:destroyed)
          expect(@imported_ticket).to eq(ticket)
          expect(@imported_ticket.assignments.pluck(:assignee_remote_id, :assignee_username)).to match_array(
            [assignee.values_at(:uid, :name)]
          )
        end
      end

      context 'when ticket has relabelled' do
        before do
          Label.import(remote_issue[:labels].first, repo)

          ticket.labels << create(:label, repo: repo)
        end

        it 'updates the labellings' do
          prior_labellings = ticket.labellings.to_a

          expect {
            @imported_ticket = subject
          }.not_to change(Label, :count)

          prior_labellings.map! do |labelling|
            begin
              labelling.reload
            rescue ActiveRecord::RecordNotFound
              :destroyed
            end
          end

          expect(prior_labellings).to all eq(:destroyed)
          expect(@imported_ticket).to eq(ticket)
          expect(ticket.reload.labels.map(&:remote_id)).to eq(remote_issue[:labels].map { |label| label[:id] })
        end
      end

      context 'when ticket has been transferred to another repo' do
        subject { described_class.import(remote_issue, repo, action: 'transferred') }

        it 'deletes ticket' do
          expect { subject }.to change { Ticket.where(id: ticket.id).count }.by(-1)
        end
      end

      context 'when ticket has been deleted' do
        subject { described_class.import(remote_issue, repo, action: 'deleted') }

        it 'deletes ticket' do
          expect { subject }.to change { Ticket.where(id: ticket.id).count }.by(-1)
        end
      end
    end
  end

  describe '#update_board_tickets_from_remote' do
    include_context 'board with swimlanes'
    include_context 'remote issue'

    let(:repo) { create(:repo, slug: slug) }
    let(:ticket) { create(:ticket, repo: repo, remote_id: issue_id, state: ticket_state) }
    let!(:board_ticket) { create(:board_ticket, ticket: ticket, board: board, swimlane: old_swimlane) }
    let!(:acceptance) { create(:swimlane, name: 'Acceptance', board: board, position: 3) }
    let!(:closed) { create(:swimlane, name: 'Closed', board: board, position: 4) }

    let(:old_swimlane) { backlog }
    let(:ticket_state) { 'open' }

    let(:payload) do
      remote_issue.merge(
        labels: [{ id: '111', name: "status: #{new_swimlane.name}", color: 'ff0000' }]
      )
    end

    subject { Ticket.import(payload, repo) }

    before do
      3.times do
        ticket = create(:ticket, repo: repo)
        create(:board_ticket, ticket: ticket, board: board, swimlane: new_swimlane)
      end
    end

    context 'when ticket has been opened' do
      let(:new_swimlane) { backlog }
      let(:payload) { remote_issue.merge(labels: []) }
      let(:ticket) { nil }
      let(:board_ticket) { nil }

      it 'moves board ticket to the top of the first swimlane' do
        ticket = Ticket.import(payload, repo)
        board_ticket = ticket.board_tickets.find_by!(board: board)

        expect(board_ticket.swimlane).to eq(backlog)
        expect(backlog.board_tickets.first).to eq(board_ticket)
      end
    end

    context 'when ticket has been closed' do
      let(:old_swimlane) { dev }
      let(:new_swimlane) { closed }

      let(:payload) do
        remote_issue.merge(
          state: 'closed',
          labels: [{ id: '111', name: "status: #{dev.name}", color: 'ff0000' }]
        )
      end

      it 'moves board ticket to the top of the last swimlane' do
        expect {
          subject
        }.to change { board_ticket.reload.swimlane }.from(dev).to(closed)
          .and change { closed.reload.board_tickets.first }.to(board_ticket)
      end
    end

    context 'when ticket has been re-opened' do
      let(:ticket_state) { 'closed' }
      let(:old_swimlane) { closed }
      let(:new_swimlane) { backlog }

      let(:payload) do
        remote_issue.merge(state: 'open', labels: [])
      end

      it 'moves board ticket to the top of the first swimlane' do
        expect {
          subject
        }.to change { board_ticket.reload.swimlane }.from(closed).to(backlog)
          .and change { backlog.reload.board_tickets.first }.to(board_ticket)
      end
    end

    context 'when ticket hasn\'t moved swimlane via label' do
      let(:new_swimlane) { board_ticket.swimlane }

      it 'does not move board ticket' do
        expect {
          subject
        }.not_to change { board_ticket.reload.swimlane }
      end
    end

    context 'when ticket has moved swimlane via label' do
      let(:new_swimlane) { acceptance }

      it 'moves board ticket to the top of the new swimlane' do
        expect {
          subject
        }.to change { board_ticket.reload.swimlane }.from(backlog).to(acceptance)
          .and change { acceptance.reload.board_tickets.first }.to(board_ticket)
      end
    end
  end
end
