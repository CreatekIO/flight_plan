require 'rails_helper'

RSpec.describe CodeReviewCompleteRule do
  let(:payload) do
    webhook_payload(:pull_request_merged).fetch(:pull_request).merge(
      id: pull_request.remote_id,
      number: pull_request.number,
      title: pull_request.title,
      body: pull_request.body
    )
  end

  let(:repo) { create(:repo) }
  let(:slug) { repo.slug }

  let!(:pull_request) { create(:pull_request, repo: repo, body: body) }

  let(:board) do
    create(
      :board,
      repos: [repo],
      swimlane_names: [
        'Backlog',
        'Development',
        'Code Review',
        'Code Review - DONE',
        'Acceptance',
        'Deploying',
        'Deployed'
      ]
    )
  end

  let(:code_review) { board.swimlanes.third }
  let(:code_review_done) { board.swimlanes.fourth }
  let(:deploying) { board.swimlanes.to_a[5] }

  subject { PullRequest.import(payload, repo) }

  before do
    Flipper.enable(:broadcasts)
    Flipper.enable_actor(:automation, board)
    Flipper.enable_actor(:automation, described_class)

    board_tickets.each do |board_ticket|
      stub_gh_get("issues/#{board_ticket.ticket.number}/labels") do
        [{ id: '111', name: "status: #{board_ticket.swimlane.name}", color: '00ff00' }]
      end

      stub_gh_put("issues/#{board_ticket.ticket.number}/labels")
    end
  end

  def create_board_ticket(swimlane:)
    create(
      :board_ticket,
      board: board,
      ticket: create(:ticket, repo: repo),
      swimlane: swimlane
    )
  end

  context 'connected to single ticket' do
    let!(:board_tickets) { [create_board_ticket(swimlane: start_swimlane)] }
    let(:board_ticket) { board_tickets.first }

    let(:body) { "Connects ##{board_ticket.ticket.number}" }

    context 'ticket in "Code Review"' do
      let(:start_swimlane) { code_review }

      it 'moves ticket to "Code Review - DONE"' do
        expect { subject }
          .to change { board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
      end

      context 'feature is disabled for board' do
        before { Flipper.disable_actor(:automation, board) }

        it 'does nothing' do
          expect { subject }.not_to change { board_ticket.reload.swimlane }
        end
      end

      context 'connected ticket connected to another PR' do
        before do
          create(:pull_request, *(:merged if other_pr_merged?), repo: repo, body: body)
        end

        context 'other PR is already merged' do
          let(:other_pr_merged?) { true }

          it 'moves ticket to "Code Review - DONE"' do
            expect { subject }
              .to change { board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
          end
        end

        context 'other PR is still open' do
          let(:other_pr_merged?) { false }

          it 'does nothing' do
            expect { subject }.not_to change { board_ticket.reload.swimlane }
          end
        end
      end
    end

    context 'ticket already in "Code Review - DONE"' do
      let(:start_swimlane) { code_review_done }

      it 'does nothing' do
        expect { subject }.not_to change { board_ticket.reload.swimlane }
      end
    end

    context 'ticket in another swimlane' do
      let(:start_swimlane) { deploying }

      it 'does nothing' do
        expect { subject }.not_to change { board_ticket.reload.swimlane }
      end
    end
  end

  context 'connected to multiple tickets' do
    let!(:board_tickets) do
      swimlanes.map { |swimlane| create_board_ticket(swimlane: swimlane) }
    end

    let(:board_ticket) { board_tickets.first }
    let(:other_board_ticket) { board_tickets.last }

    let(:body) do
      board_tickets.map { |board_ticket| "Connects ##{board_ticket.ticket.number}" }.join("\n")
    end

    context 'both tickets in "Code Review"' do
      let(:swimlanes) { Array.new(2) { code_review } }

      it 'moves both tickets to "Code Review - DONE"' do
        expect { subject }
          .to change { board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
          .and change { other_board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
      end

      context 'one connected ticket also connected to another PR' do
        before do
          create(
            :pull_request,
            *(:merged if other_pr_merged?),
            repo: repo,
            body: "Connects ##{other_board_ticket.ticket.number}"
          )
        end

        context 'other PR is already merged' do
          let(:other_pr_merged?) { true }

          it 'moves both tickets to "Code Review - DONE"' do
            expect { subject }
              .to change { board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
              .and change { other_board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
          end
        end

        context 'other PR is still open' do
          let(:other_pr_merged?) { false }

          it 'only moves ticket with all-merged PRs to "Code Review - DONE"' do
            expect { subject }
              .to change { board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
              .and not_change { other_board_ticket.reload.swimlane }
          end
        end
      end
    end

    context 'one ticket in "Code Review"' do
      let(:swimlanes) { [code_review, deploying] }

      it 'only moves ticket in "Code Review" to "Code Review - DONE"' do
        expect { subject }
          .to change { board_ticket.reload.swimlane }.from(code_review).to(code_review_done)
          .and not_change { other_board_ticket.reload.swimlane }
      end
    end
  end
end
