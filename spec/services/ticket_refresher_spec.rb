require 'rails_helper'

RSpec.describe TicketRefresher do
  describe '#run' do
    let(:repo) { create(:repo) }
    let(:remote_url) { repo.remote_url }
    let!(:ticket) { create(:ticket, repo: repo) }
    let!(:pull_request) { create(:pull_request, repo: repo) }

    subject { described_class.new(ticket) }

    let(:gh_ticket_payload) do
      {
        url: expand_gh_url("issues/#{ticket.remote_number}"),
        id: ticket.remote_id,
        number: ticket.remote_number,
        title: "Ticket #{SecureRandom.uuid}",
        body: 'Connects #',
        state: 'open',
        assignees: [],
        labels: [],
        milestone: nil
      }
    end

    let!(:gh_issue_stub) do
      stub_gh_get("issues/#{ticket.remote_number}") do
        gh_ticket_payload
      end
    end

    let(:gh_comments_payload) do
      [{ id: 1000 }, { id: 1001 }]
    end

    let!(:gh_comments_stub) do
      stub_gh_get("issues/#{ticket.remote_number}/comments") do
        gh_comments_payload
      end
    end

    around do |example|
      Sidekiq::Testing.fake! do
        example.run
        Sidekiq::Worker.clear_all
      end
    end

    before do
      Comment.import(
        { comment: gh_comments_payload.last, issue: gh_ticket_payload },
        repo
      )

      PullRequestConnection.create!(
        ticket: ticket,
        pull_request: pull_request
      )

      allow(Ticket).to receive(:import).and_call_original
      allow(Comment).to receive(:import).and_call_original
    end

    it 'updates ticket itself' do
      subject.run

      aggregate_failures do
        expect(gh_issue_stub).to have_been_requested
        expect(Ticket).to have_received(:import).with(
          gh_ticket_payload,
          full_name: repo.remote_url
        )
      end
    end

    it 'updates comments on ticket' do
      aggregate_failures do
        expect { subject.run }.to change(Comment, :count).by(1)
        expect(gh_comments_stub).to have_been_requested

        gh_comments_payload.each do |gh_comment|
          expect(Comment).to have_received(:import).with(
            { comment: gh_comment, issue: gh_ticket_payload },
            repo
          )
        end
      end
    end

    it 'updates linked pull requests' do
      subject.run

      expect(
        PullRequestRefreshWorker.jobs.map { |job| job['args'] }
      ).to eq([[pull_request.id]])
    end
  end
end
