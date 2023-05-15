require 'rails_helper'

RSpec.describe PullRequest do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to have_many(:pull_request_connections) }
    it { is_expected.to have_many(:tickets).through(:pull_request_connections) }
    it { is_expected.to have_many(:reviews).with_primary_key(:remote_id) }
  end

  describe '.import' do
    include_context 'board with swimlanes'
    include_context 'remote pull request'

    subject { described_class.import(remote_pull_request, repo) }

    context 'when the pull request does not already exist' do
      it 'adds the pull_request to the repo' do
        expect { subject }.to change { repo.pull_request_models.count }.by(1)

        expect(subject.title).to eq('pull request title')
      end
    end

    context 'when the pull request exists' do
      it 'updates the pull request' do
        pull_request = create(:pull_request, title: 'before title', repo: repo, remote_id: pull_request_id)

        expect { subject }.not_to change { repo.pull_request_models.count }

        expect(pull_request.reload.title).to eq('pull request title')
      end
    end
  end

  describe '#merge_status=' do
    it 'transforms values from GitHub\'s API to our values' do
      aggregate_failures do
        expect(described_class.new(merge_status: nil).merge_status).to eq('merge_status_unknown')
        expect(described_class.new(merge_status: false).merge_status).to eq('merge_conflicts')
        expect(described_class.new(merge_status: true).merge_status).to eq('merge_ok')
      end
    end
  end

  describe '#update_pull_request_connections' do
    let(:repo) { create(:repo) }
    let!(:board) { create(:board, repos: [repo]) }

    def connection_counts
      pull_request.pull_request_connections.group(:ticket).count
    end

    context 'referencing ticket in same repo' do
      let!(:branch_ticket) { create(:ticket, repo: repo) }
      let!(:body_ticket) { create(:ticket, repo: repo) }

      let(:pull_request) do
        build(
          :pull_request,
          repo: repo,
          head_branch: "feature/##{branch_ticket.number}-test",
          body: "Connects ##{body_ticket.number}"
        )
      end

      context 'new pull request' do
        it 'creates connections from branch name and body' do
          expect {
            pull_request.save!
          }.to change {
            connection_counts
          }.from({}).to(branch_ticket => 1, body_ticket => 1)
        end
      end

      context 'existing pull request' do
        let(:new_branch_ticket) { create(:ticket, repo: repo) }
        let(:new_body_ticket) { create(:ticket, repo: repo) }

        it 'updates connections from branch name and body' do
          pull_request.save!

          pull_request.head_branch = "bug/##{new_branch_ticket.number}-test"
          pull_request.body += "\nConnects ##{new_body_ticket.number}"

          expect {
            pull_request.save!
          }.to change {
            connection_counts
          }.from(branch_ticket => 1, body_ticket => 1)
            .to(new_branch_ticket => 1, body_ticket => 1, new_body_ticket => 1)
        end
      end
    end

    context 'referencing ticket in different repo' do
      let!(:body_ticket) { create(:ticket, repo: other_repo) }

      context 'on the same board' do
        let!(:other_repo) { create(:repo, boards: [board]) }

        let(:pull_request) do
          build(
            :pull_request,
            repo: repo,
            body: "Connects #{other_repo.slug}##{body_ticket.number}"
          )
        end

        context 'new pull request' do
          it 'creates connections from branch name and body' do
            expect {
              pull_request.save!
            }.to change { connection_counts }.from({}).to(body_ticket => 1)
          end
        end

        context 'existing pull request' do
          let(:new_body_ticket) { create(:ticket, repo: other_repo) }

          it 'updates connections from branch name and body' do
            pull_request.save!

            pull_request.body += "\nConnects #{other_repo.slug}##{new_body_ticket.number}"

            expect {
              pull_request.save!
            }.to change {
              connection_counts
            }.from(body_ticket => 1).to(body_ticket => 1, new_body_ticket => 1)
          end
        end
      end

      context 'on a different board' do
        let(:other_board) { create(:board) }
        let!(:other_repo) { create(:repo, boards: [other_board]) }

        let(:pull_request) do
          build(
            :pull_request,
            repo: repo,
            body: "Connects #{other_repo.slug}##{body_ticket.number}"
          )
        end

        context 'new pull request' do
          it 'doesn\'t create any connections' do
            pull_request.save!

            expect(connection_counts).to be_empty
          end
        end

        context 'existing pull request' do
          let(:new_body_ticket) { create(:ticket, repo: other_repo) }

          it 'doesn\'t create any connections' do
            pull_request.save!
            pull_request.body += "\nConnects #{other_repo.slug}##{new_body_ticket.number}"

            pull_request.save!

            expect(connection_counts).to be_empty
          end
        end
      end
    end
  end
end
