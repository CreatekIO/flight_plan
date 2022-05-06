require 'rails_helper'

RSpec.describe LabellingsController, type: :request do
  describe 'PATCH #update' do
    let(:repo) { create(:repo) }
    let(:board) { create(:board, repos: [repo]) }
    let(:swimlane) { create(:swimlane, board: board) }
    let(:ticket) { create(:ticket, repo: repo, labels: starting_labels) }
    let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: swimlane) }
    let(:existing_label) { create(:label, repo: repo) }
    let(:swimlane_label) { create(:label, name: "status: #{swimlane.name.downcase}", repo: repo) }

    let(:user) { build_stubbed(:user) }

    let(:path) { board_ticket_labelling_path(board, board_ticket, format: :json) }

    let(:github_token) { "github_token_#{user.id}" }
    let(:slug) { repo.slug }
    let(:starting_labels) { [existing_label, swimlane_label] }
    let!(:remaining_labels) { starting_labels.dup }

    def remaining_labels_response
      remaining_labels
        .map { |label| { id: label.remote_id, name: label.name, color: label.colour } }
        .to_json
    end

    let!(:add_labels_request) do
      stub_gh_post("issues/#{ticket.number}/labels", anything) do
        proc do |request|
          JSON.parse(request.body).each do |name|
            remaining_labels << (Label.find_by(name: name) || build_stubbed(:label, name: name))
          end
          remaining_labels_response
        end
      end.with(headers: { 'Authorization' => "token #{github_token}" })
    end

    let(:delete_url_pattern) { "issues/#{ticket.number}/labels/{name}" }
    let(:delete_label_template) { Addressable::Template.new(expand_gh_url(delete_url_pattern)) }

    let!(:remove_labels_request) do
      # Using a proc means that we can delete labels in any order and
      # still get the correct response
      stub_gh_delete(delete_url_pattern, status: 200) do
        proc do |request|
          parsed = delete_label_template.extract(request.uri.omit(:port))
          raise 'no label name' if parsed.blank? || parsed['name'].blank?

          remaining_labels.reject! { |label| label.name == parsed['name'] }
          remaining_labels_response
        end
      end.with(headers: { 'Authorization' => "token #{github_token}" })
    end

    before do
      sign_in user, github_token: { oauth: github_token }
    end

    subject do
      patch path, params: { labelling: params }
    end

    context 'adding a single label' do
      let!(:new_label) { create(:label, repo: repo) }
      let(:params) { { add: [new_label.name] } }

      it 'adds new label whilst retaining existing labels' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.labels.reload.group(:name).count
          }.from(
            existing_label.name => 1, swimlane_label.name => 1
          ).to(
            existing_label.name => 1, swimlane_label.name => 1, new_label.name => 1
          ).and not_change { Label.count }

          expect(
            add_labels_request.with(body: [new_label.name].to_json)
          ).to have_been_requested.once
        end
      end

      it 'returns latest labels on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to match_array(
            [
              a_hash_including('name' => existing_label.name),
              a_hash_including('name' => new_label.name)
            ]
          )
        end
      end

      context 'label does not exist in db' do
        let(:label_name) { 'test label to add' }
        let(:params) { { add: [label_name] } }

        it 'adds new label whilst retaining existing labels' do
          aggregate_failures do
            expect { subject }.to change {
              ticket.labels.reload.group(:name).count
            }.from(
              existing_label.name => 1, swimlane_label.name => 1
            ).to(
              existing_label.name => 1, swimlane_label.name => 1, label_name => 1
            ).and change { Label.where(name: label_name).count }.by(1)

            expect(
              add_labels_request.with(body: [label_name].to_json)
            ).to have_been_requested.once
          end
        end
      end
    end

    context 'adding multiple labels' do
      let(:new_labels) { create_pair(:label, repo: repo) }
      let(:label_names) { new_labels.map(&:name) }
      let(:params) { { add: label_names } }

      it 'adds new labels whilst retaining existing labels' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.labels.reload.group(:name).count
          }.from(
            existing_label.name => 1, swimlane_label.name => 1
          ).to(
            existing_label.name => 1, swimlane_label.name => 1, label_names.first => 1, label_names.second => 1
          )

          expect(
            add_labels_request.with(body: label_names.to_json)
          ).to have_been_requested.once
        end
      end

      it 'returns latest labels on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to match_array(
            [
              a_hash_including('name' => existing_label.name),
              a_hash_including('name' => label_names.first),
              a_hash_including('name' => label_names.second)
            ]
          )
        end
      end
    end

    context 'removing a single label' do
      let(:params) { { remove: [existing_label.name] } }

      it 'removes specified label whilst retaining remaining labels' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.labels.reload.group(:name).count
          }.from(
            existing_label.name => 1, swimlane_label.name => 1
          ).to(
            swimlane_label.name => 1
          )

          expect(WebMock).to have_requested(
            :delete,
            delete_label_template.expand(name: existing_label.name)
          ).once
        end
      end

      it 'returns latest labels on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to eq([])
        end
      end
    end

    context 'removing multiple labels' do
      let(:labels_to_remove) { create_pair(:label, repo: repo) }
      let(:other_label) { create(:label, repo: repo) }
      let(:starting_labels) { [*labels_to_remove, swimlane_label, other_label] }

      let(:params) { { remove: labels_to_remove.map(&:name) } }

      it 'removes specified labels whilst retaining remaining labels' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.labels.reload.group(:name).count
          }.from(
            labels_to_remove.first.name => 1,
            labels_to_remove.second.name => 1,
            swimlane_label.name => 1,
            other_label.name => 1
          ).to(
            swimlane_label.name => 1, other_label.name => 1
          )

          labels_to_remove.each do |label|
            expect(WebMock).to have_requested(:delete, delete_label_template.expand(name: label.name)).once
          end
        end
      end

      it 'returns latest labels on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to match_array(
            [a_hash_including('name' => other_label.name)]
          )
        end
      end
    end

    context 'adding and removing multiple labels' do
      let!(:labels_to_add) { create_pair(:label, repo: repo) }
      let!(:labels_to_remove) { create_pair(:label, repo: repo) }
      let!(:other_label) { create(:label, repo: repo) }
      let!(:starting_labels) { [*labels_to_remove, swimlane_label, other_label] }

      let(:params) do
        { add: labels_to_add.map(&:name), remove: labels_to_remove.map(&:name) }
      end

      it 'adds and removes specified labels whilst retaining remaining labels' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.labels.reload.group(:name).count
          }.from(
            labels_to_remove.first.name => 1,
            labels_to_remove.second.name => 1,
            swimlane_label.name => 1,
            other_label.name => 1
          ).to(
            swimlane_label.name => 1,
            other_label.name => 1,
            labels_to_add.first.name => 1,
            labels_to_add.second.name => 1
          )

          expect(
            add_labels_request.with(body: labels_to_add.map(&:name).to_json)
          ).to have_been_requested.once

          labels_to_remove.each do |label|
            expect(WebMock).to have_requested(:delete, delete_label_template.expand(name: label.name)).once
          end
        end
      end

      it 'returns latest labels on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to match_array(
            [
              a_hash_including('name' => other_label.name),
              a_hash_including('name' => labels_to_add.first.name),
              a_hash_including('name' => labels_to_add.second.name)
            ]
          )
        end
      end

      context 'deletion fails' do
        let!(:remove_labels_request) do
          stub_gh_delete(delete_url_pattern, status: 500) do
            { error: 'Server error' }
          end
        end

        it 'still updates successful label additions' do
          aggregate_failures do
            expect { subject }.to change {
              ticket.labels.reload.group(:name).count
            }.from(
              labels_to_remove.first.name => 1,
              labels_to_remove.second.name => 1,
              swimlane_label.name => 1,
              other_label.name => 1
            ).to(
              swimlane_label.name => 1,
              other_label.name => 1,
              labels_to_remove.first.name => 1,
              labels_to_remove.second.name => 1,
              labels_to_add.first.name => 1,
              labels_to_add.second.name => 1
            )

            expect(
              add_labels_request.with(body: labels_to_add.map(&:name).to_json)
            ).to have_been_requested.once
          end
        end

        it 'returns error' do
          subject

          aggregate_failures do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(json).to eq(
              'errors' => [
                "Unable to remove labels '#{labels_to_remove.first.name}', '#{labels_to_remove.second.name}'"
              ]
            )
          end
        end
      end

      context 'addition fails' do
        let!(:add_labels_request) do
          stub_gh_post("issues/#{ticket.number}/labels", anything, status: 500) do
            { error: 'Server error' }
          end
        end

        it 'still updates successful label deletions' do
          aggregate_failures do
            expect { subject }.to change {
              ticket.labels.reload.group(:name).count
            }.from(
              labels_to_remove.first.name => 1,
              labels_to_remove.second.name => 1,
              swimlane_label.name => 1,
              other_label.name => 1
            ).to(
              swimlane_label.name => 1,
              other_label.name => 1
            )

            labels_to_remove.each do |label|
              expect(WebMock).to have_requested(:delete, delete_label_template.expand(name: label.name)).once
            end
          end
        end

        it 'returns error' do
          subject

          aggregate_failures do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(json).to eq(
              'errors' => [
                "Unable to add labels '#{labels_to_add.first.name}', '#{labels_to_add.second.name}'"
              ]
            )
          end
        end
      end

      context 'everything fails' do
        let!(:add_labels_request) do
          stub_gh_post("issues/#{ticket.number}/labels", anything, status: 500) do
            { error: 'Server error' }
          end
        end

        let!(:remove_labels_request) do
          stub_gh_delete(delete_url_pattern, status: 500) do
            { error: 'Server error' }
          end
        end

        it 'makes no changes to db' do
          aggregate_failures do
            expect { subject }
              .to not_change { ticket.labels.reload }
              .and not_change { Label.count }
          end
        end

        it 'returns error' do
          subject

          aggregate_failures do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(json).to eq(
              'errors' => [
                "Unable to add labels '#{labels_to_add.first.name}', '#{labels_to_add.second.name}'" \
                " or remove labels '#{labels_to_remove.first.name}', '#{labels_to_remove.second.name}'"
              ]
            )
          end
        end
      end
    end

    context 'labels were updated on GitHub' do
      let(:label_to_add) { create(:label, repo: repo) }
      let(:label_to_remove) { create(:label, repo: repo) }
      let(:other_label) { create(:label, repo: repo) }
      let(:starting_labels) { [label_to_remove, swimlane_label, other_label] }

      let(:new_label) { build_stubbed(:label) }

      let(:params) do
        { add: [label_to_add.name], remove: [label_to_remove.name] }
      end

      def remaining_labels_response
        (JSON.parse(super) + [
          { id: new_label.remote_id, name: new_label.name, color: new_label.colour }
        ]).to_json
      end

      it 'imports new label' do
        aggregate_failures do
          expect { subject }.to change {
            ticket.labels.reload.group(:name).count
          }.from(
            label_to_remove.name => 1,
            swimlane_label.name => 1,
            other_label.name => 1
          ).to(
            swimlane_label.name => 1,
            other_label.name => 1,
            label_to_add.name => 1,
            new_label.name => 1
          ).and change { Label.where(name: new_label.name).count }.by(1)
        end
      end

      it 'returns latest labels on ticket with OK status' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(json).to match_array(
            [
              a_hash_including('name' => other_label.name),
              a_hash_including('name' => label_to_add.name),
              a_hash_including('name' => new_label.name)
            ]
          )
        end
      end
    end
  end
end
