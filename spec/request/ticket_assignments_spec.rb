require 'rails_helper'

RSpec.describe TicketAssignmentsController, type: :request do
  describe 'PATCH #update' do
    let(:repo) { create(:repo) }
    let(:board) { create(:board, repos: [repo]) }
    let(:swimlane) { create(:swimlane, board: board) }
    let(:ticket) { create(:ticket, repo: repo, assignments: starting_assignments) }
    let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: swimlane) }
    let(:existing_assignment) { build(:ticket_assignment) }

    let(:user) { build_stubbed(:user) }

    let(:path) { board_ticket_assignment_path(board, board_ticket, format: :json) }

    let(:github_token) { "github_token_#{user.id}" }
    let(:slug) { repo.slug }
    let(:starting_assignments) { [existing_assignment] }

    let!(:remaining_assignments) do
      starting_assignments.index_by(&:assignee_username).transform_values(&:assignee_remote_id)
    end

    def remote_response
      Jbuilder.encode do |json|
        json.id ticket.remote_id
        json.extract! ticket, :number, :title, :body, :state
        json.assignees remaining_assignments.to_a do |(username, id)|
          json.id id
          json.login username
        end
        json.labels []
        json.milestone nil
      end
    end

    let!(:add_assignees_request) do
      stub_gh_post("issues/#{ticket.number}/assignees", anything) do
        proc do |request|
          JSON.parse(request.body).fetch('assignees').each do |username|
            remaining_assignments[username] ||= generate(:user_id)
          end

          remote_response
        end
      end.with(headers: { 'Authorization' => "token #{github_token}" })
    end

    let!(:remove_assignees_request) do
      stub_gh_delete("issues/#{ticket.number}/assignees", status: 200) do
        proc do |request|
          names = JSON.parse(request.body).fetch('assignees')
          remaining_assignments.except!(*names)

          remote_response
        end
      end.with(headers: { 'Authorization' => "token #{github_token}" })
    end

    before do
      sign_in user, github_token: { oauth: github_token }
    end

    subject do
      patch path, params: { assignment: params }
    end

    context 'assigning a single assignee' do
      let!(:username) { build(:ticket_assignment).assignee_username }
      let(:params) { { add: [username] } }

      it 'assigns user whilst retaining existing assignees' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.assignments.reload.group(:assignee_username).count
          }.from(
            existing_assignment.assignee_username => 1
          ).to(
            existing_assignment.assignee_username => 1, username => 1
          )

          expect(
            add_assignees_request.with(body: { assignees: [username] }.to_json)
          ).to have_been_requested.once
        end
      end

      it 'returns latest assignees on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to contain_exactly(
            a_hash_including('username' => existing_assignment.assignee_username),
            a_hash_including('username' => username)
          )
        end
      end
    end

    context 'assigning multiple users' do
      let(:usernames) { build_pair(:ticket_assignment).map(&:assignee_username) }
      let(:params) { { add: usernames } }

      it 'assigns users whilst retaining existing assignees' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.assignments.reload.group(:assignee_username).count
          }.from(
            existing_assignment.assignee_username => 1
          ).to(
            existing_assignment.assignee_username => 1, usernames.first => 1, usernames.second => 1
          )

          expect(
            add_assignees_request.with(body: { assignees: usernames }.to_json)
          ).to have_been_requested.once
        end
      end

      it 'returns latest assignees on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to contain_exactly(
            a_hash_including('username' => existing_assignment.assignee_username),
            a_hash_including('username' => usernames.first),
            a_hash_including('username' => usernames.second)
          )
        end
      end
    end

    context 'unassigning a single user' do
      let(:starting_assignments) { build_pair(:ticket_assignment) }
      let(:to_remove) { starting_assignments.first }
      let(:to_retain) { starting_assignments.second }

      let(:params) { { remove: [to_remove.assignee_username] } }

      it 'unassigns specified user whilst retaining remaining assignees' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.assignments.reload.group(:assignee_username).count
          }.from(
            to_remove.assignee_username => 1, to_retain.assignee_username => 1
          ).to(
            to_retain.assignee_username => 1,
          )

          expect(
            remove_assignees_request.with(
              body: { assignees: [to_remove.assignee_username] }.to_json
            )
          ).to have_been_requested.once
        end
      end

      it 'returns latest assignees on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to contain_exactly(
            a_hash_including('username' => to_retain.assignee_username)
          )
        end
      end
    end

    context 'unassigning multiple users' do
      let(:starting_assignments) { build_list(:ticket_assignment, 3) }
      let(:to_remove) { starting_assignments.first(2) }
      let(:to_retain) { starting_assignments.last }

      let(:params) { { remove: to_remove.map(&:assignee_username) } }

      it 'unassigns specified users whilst retaining remaining assignees' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.assignments.reload.group(:assignee_username).count
          }.from(
            to_remove.first.assignee_username => 1,
            to_remove.second.assignee_username => 1,
            to_retain.assignee_username => 1
          ).to(
            to_retain.assignee_username => 1
          )

          expect(
            remove_assignees_request.with(body: { assignees: params[:remove] }.to_json)
          ).to have_been_requested.once
        end
      end

      it 'returns latest assignees on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to contain_exactly(
            a_hash_including('username' => to_retain.assignee_username)
          )
        end
      end
    end

    context 'adding and removing multiple assignees' do
      let!(:to_add) { build_pair(:ticket_assignment) }
      let!(:to_remove) { build_pair(:ticket_assignment) }
      let!(:to_retain) { build(:ticket_assignment) }
      let!(:starting_assignments) { [*to_remove, *to_remove, to_retain] }

      let(:params) do
        { add: to_add.map(&:assignee_username), remove: to_remove.map(&:assignee_username) }
      end

      it 'adds and removes specified assignees whilst retaining remaining assignees' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.assignments.reload.group(:assignee_username).count
          }.from(
            to_remove.first.assignee_username => 1,
            to_remove.second.assignee_username => 1,
            to_retain.assignee_username => 1
          ).to(
            to_retain.assignee_username => 1,
            to_add.first.assignee_username => 1,
            to_add.second.assignee_username => 1
          )

          expect(
            add_assignees_request.with(
              body: { assignees: to_add.map(&:assignee_username) }.to_json
            )
          ).to have_been_requested.once

          expect(
            remove_assignees_request.with(
              body: { assignees: to_remove.map(&:assignee_username) }.to_json
            )
          ).to have_been_requested.once
        end
      end

      it 'returns latest assignees on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to contain_exactly(
            a_hash_including('username' => to_retain.assignee_username),
            a_hash_including('username' => to_add.first.assignee_username),
            a_hash_including('username' => to_add.second.assignee_username)
          )
        end
      end

      context 'deletion fails' do
        let!(:remove_assignees_request) do
          stub_gh_delete("issues/#{ticket.number}/assignees", status: 500) do
            { error: 'Server error' }
          end
        end

        it 'still updates successful assignments' do
          aggregate_failures do
            expect { subject }.to change {
              ticket.assignments.reload.group(:assignee_username).count
            }.from(
              to_remove.first.assignee_username => 1,
              to_remove.second.assignee_username => 1,
              to_retain.assignee_username => 1
            ).to(
              to_retain.assignee_username => 1,
              to_remove.first.assignee_username => 1,
              to_remove.second.assignee_username => 1,
              to_add.first.assignee_username => 1,
              to_add.second.assignee_username => 1
            )

            expect(
              add_assignees_request.with(
                body: { assignees: to_add.map(&:assignee_username) }.to_json
              )
            ).to have_been_requested.once
          end
        end

        it 'returns error' do
          subject

          aggregate_failures do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(json).to eq(
              'errors' => [
                "Unable to unassign @#{to_remove.first.assignee_username}, @#{to_remove.second.assignee_username}"
              ]
            )
          end
        end
      end

      context 'addition fails' do
        let!(:add_assignees_request) do
          stub_gh_post("issues/#{ticket.number}/assignees", anything, status: 500) do
            { error: 'Server error' }
          end
        end

        it 'still updates successful unassignments' do
          aggregate_failures do
            expect { subject }.to change {
              ticket.assignments.reload.group(:assignee_username).count
            }.from(
              to_remove.first.assignee_username => 1,
              to_remove.second.assignee_username => 1,
              to_retain.assignee_username => 1
            ).to(
              to_retain.assignee_username => 1
            )

            expect(
              remove_assignees_request.with(
                body: { assignees: to_remove.map(&:assignee_username) }.to_json
              )
            ).to have_been_requested.once
          end
        end

        it 'returns error' do
          subject

          aggregate_failures do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(json).to eq(
              'errors' => [
                "Unable to assign @#{to_add.first.assignee_username}, @#{to_add.second.assignee_username}"
              ]
            )
          end
        end
      end

      context 'everything fails' do
        let!(:add_assignees_request) do
          stub_gh_post("issues/#{ticket.number}/assignees", anything, status: 500) do
            { error: 'Server error' }
          end
        end

        let!(:remove_assignees_request) do
          stub_gh_delete("issues/#{ticket.number}/assignees", status: 500) do
            { error: 'Server error' }
          end
        end

        it 'makes no changes to db' do
          expect { subject }.to not_change { ticket.assignments.reload }
        end

        it 'returns error' do
          subject

          aggregate_failures do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(json).to eq(
              'errors' => [
                "Unable to assign @#{to_add.first.assignee_username}, @#{to_add.second.assignee_username}" \
                " or unassign @#{to_remove.first.assignee_username}, @#{to_remove.second.assignee_username}"
              ]
            )
          end
        end
      end
    end

    context 'assignees were updated on GitHub' do
      let(:to_add) { build(:ticket_assignment) }
      let(:to_remove) { build(:ticket_assignment) }
      let(:to_retain) { build(:ticket_assignment) }
      let(:starting_assignments) { [to_remove, to_retain] }

      let(:new_assignee) { build_stubbed(:ticket_assignment) }

      let(:params) do
        { add: [to_add.assignee_username], remove: [to_remove.assignee_username] }
      end

      def remote_response
        original = JSON.parse(super)
        original['assignees'] << { id: new_assignee.assignee_remote_id, login: new_assignee.assignee_username }
        original.to_json
      end

      it 'imports new assignee' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.assignments.reload.group(:assignee_username).count
          }.from(
            to_remove.assignee_username => 1,
            to_retain.assignee_username => 1
          ).to(
            to_retain.assignee_username => 1,
            to_add.assignee_username => 1,
            new_assignee.assignee_username => 1
          )
        end
      end

      it 'returns latest assignees on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to contain_exactly(
            a_hash_including('username' => to_retain.assignee_username),
            a_hash_including('username' => to_add.assignee_username),
            a_hash_including('username' => new_assignee.assignee_username)
          )
        end
      end
    end
  end
end
