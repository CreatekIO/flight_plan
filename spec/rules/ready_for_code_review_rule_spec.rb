require 'rails_helper'

RSpec.describe ReadyForCodeReviewRule do
  let(:payload) do
    webhook_payload(:pull_request_opened).fetch(:pull_request).merge(
      body: "Connects ##{ticket.number}"
    )
  end

  let(:repo) { create(:repo) }
  let(:slug) { repo.slug }
  let(:ticket) { create(:ticket, repo: repo) }

  let!(:board_ticket) do
    create(:board_ticket, board: board, ticket: ticket, swimlane: start_swimlane)
  end

  let(:board) do
    create(
      :board,
      repos: [repo],
      swimlane_names: ['Backlog', 'Development', 'Demo', 'Demo - DONE', 'Code Review', 'Acceptance', 'Deployed']
    )
  end

  let(:development) { board.swimlanes.second }
  let(:demo_done) { board.swimlanes.fourth }
  let(:code_review) { board.swimlanes.fifth }

  subject { PullRequest.import(payload, repo) }

  before do
    Flipper.enable(:broadcasts)

    stub_gh_get("issues/#{ticket.number}/labels") do
      [{ id: '111', name: "status: #{board_ticket.swimlane.name}", color: '00ff00' }]
    end

    stub_gh_put("issues/#{ticket.number}/labels")
  end

  context 'ticket in "Development"' do
    let(:start_swimlane) { development }

    it 'moves ticket to "Code Review"' do
      expect { subject }
        .to change { board_ticket.reload.swimlane }.from(development).to(code_review)
    end
  end

  context 'ticket in "Demo - DONE"' do
    let(:start_swimlane) { demo_done }

    it 'moves ticket to "Code Review"' do
      expect { subject }
        .to change { board_ticket.reload.swimlane }.from(demo_done).to(code_review)
    end
  end

  context 'ticket in another swimlane' do
    let(:start_swimlane) { code_review }

    it 'does nothing' do
      expect { subject }.not_to change { board_ticket.reload.swimlane }
    end
  end
end
