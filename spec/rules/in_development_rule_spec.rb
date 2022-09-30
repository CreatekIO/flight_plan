require 'rails_helper'

RSpec.describe InDevelopmentRule do
  let(:payload) do
    webhook_payload(:branch_created_push).deep_merge(
      ref: "refs/heads/#{branch_name}",
      repository: {
        id: repo.remote_id,
        full_name: repo.slug
      }
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
      swimlane_names: ['Backlog', 'Planning - DONE', 'Development', 'Acceptance', 'Deployed']
    )
  end

  let(:planning_done) { board.swimlanes.second }
  let(:development) { board.swimlanes.third }

  subject { PushImporter.import(payload, repo) }

  before do
    Flipper.enable(:broadcasts)
    Flipper.enable(:automation)

    described_class.enable!(board)

    stub_gh_get("issues/#{ticket.number}/labels") do
      [{ id: '111', name: "status: #{board_ticket.swimlane.name}", color: '00ff00' }]
    end

    stub_gh_put("issues/#{ticket.number}/labels")
  end

  context 'matching criteria' do
    let(:start_swimlane) { planning_done }
    let(:branch_name) { "feature/##{ticket.number}-#{ticket.title.parameterize}" }

    it 'moves ticket to "Development" and assigns pusher' do
      expect { subject }
        .to change { board_ticket.reload.swimlane }.from(planning_done).to(development)
        .and change { ticket.assignments.pluck(:assignee_username, :assignee_remote_id) }
        .from([]).to([payload[:sender].values_at(:login, :id)])
    end

    context 'rule is disabled for board' do
      before do
        BoardRule.where(board: board, rule_class: described_class.name).delete_all
      end

      it 'does nothing' do
        expect { subject }
          .to not_change { board_ticket.reload.swimlane }
          .and not_change { ticket.assignments.pluck(:assignee_username, :assignee_remote_id) }
      end
    end

    context 'branch already exists' do
      let!(:branch) { create(:branch, :with_head, name: branch_name, repo: repo) }
      let(:payload) { super().merge(before: branch.latest_head.head_sha) }

      it 'moves ticket to "Development" and assigns pusher' do
        expect { subject }
          .to change { board_ticket.reload.swimlane }.from(planning_done).to(development)
          .and change { ticket.assignments.pluck(:assignee_username, :assignee_remote_id) }
          .from([]).to([payload[:sender].values_at(:login, :id)])
      end

      context 'push deletes branch' do
        let(:payload) do
          webhook_payload(:branch_deleted_push).deep_merge(
            ref: "refs/heads/#{branch_name}",
            before: branch.latest_head.head_sha,
            repository: {
              id: repo.remote_id,
              full_name: repo.slug
            }
          )
        end

        it 'does nothing' do
          expect { subject }
            .to not_change { board_ticket.reload.swimlane }
            .and not_change { ticket.assignments.pluck(:assignee_username, :assignee_remote_id) }
        end
      end
    end

    context 'user already assigned to ticket' do
      before do
        create(
          :ticket_assignment,
          ticket: ticket,
          assignee_remote_id: payload[:sender][:id],
          # deliberately different from payload to test that
          # we only use the remote id
          assignee_username: 'a-different-username'
        )
      end

      it 'just moves ticket to "Development"' do
        expect { subject }
          .to change { board_ticket.reload.swimlane }.from(planning_done).to(development)
          .and not_change { ticket.assignments.pluck(:assignee_username, :assignee_remote_id) }
      end
    end
  end

  context 'push to non-feature branch' do
    let(:start_swimlane) { planning_done }
    let(:branch_name) { 'develop' }

    it 'does nothing' do
      expect { subject }
        .to not_change { board_ticket.reload.swimlane }
        .and not_change { ticket.assignments.pluck(:assignee_username, :assignee_remote_id) }
    end
  end

  context 'not in "planning - DONE" swimlane' do
    let(:start_swimlane) { board.swimlanes.first }
    let(:branch_name) { "feature/##{ticket.number}-#{ticket.title.parameterize}" }

    it 'does nothing' do
      expect { subject }
        .to not_change { board_ticket.reload.swimlane }
        .and not_change { ticket.assignments.pluck(:assignee_username, :assignee_remote_id) }
    end
  end
end
