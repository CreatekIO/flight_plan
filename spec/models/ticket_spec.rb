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

    let(:subject) { described_class.import(remote_issue, remote_repo) }

    context 'when the ticket does not already exist' do
      it 'adds the issue to the repo' do
        expect {
          @ticket = subject
        }.to change { repo.tickets.count }.by(1)

        expect(@ticket.remote_title).to eq('issue title')
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
    end

    context 'when the ticket exists' do
      let!(:ticket) { create(:ticket, remote_title: 'before title', repo: repo, remote_id: issue_id) }

      it 'updates the ticket' do
        expect {
          @imported_ticket = subject
        }.not_to change { repo.tickets.count }

        expect(@imported_ticket).to eq(ticket)
        expect(ticket.reload.remote_title).to eq(remote_issue[:title])
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
    end
  end

  describe '.find_by_remote' do
    let(:remote_issue_id) { 100 }
    let(:remote_issue) {
      {
        id: remote_issue_id
      }
    }
    let(:remote_repo) {
      {
        full_name: 'org_name/repo_name'
      }
    }
    let!(:repo) { create(:repo, remote_url: 'org_name/repo_name') }
    context "when the ticket doesn't exist" do
      it 'builds a new ticket' do
        ticket = described_class.find_by_remote(remote_issue, remote_repo)
        expect(ticket.persisted?).to be(false)
      end
    end
    context "when the ticket exists" do
      it 'finds the ticket' do
        create(:ticket, repo: repo, remote_id: remote_issue_id)
        ticket = described_class.find_by_remote(remote_issue, remote_repo)
        expect(ticket.persisted?).to be(true)
      end
    end
  end

  describe '#update_board_tickets_from_remote' do
    pending
  end
end
