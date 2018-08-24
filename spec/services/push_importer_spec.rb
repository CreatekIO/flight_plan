require 'rails_helper'

RSpec.describe PushImporter do
  describe '#import' do
    let(:repo) { create(:repo) }
    let(:payload) { webhook_payload(:branch_updated_push).merge!(ref: ref) }

    subject { described_class.new(payload, repo) }

    before do
      allow(Branch).to receive(:import).and_return(branch)
      allow(repo).to receive(:update_merged_tickets)
    end

    context 'with a tag push' do
      let(:branch) { nil }
      let(:ref) { 'refs/tags/some-tag' }

      it 'doesn\'t perform import' do
        subject.import

        expect(Branch).not_to have_received(:import)
      end
    end

    context 'with a branch push' do
      let(:branch) { create(:branch, repo: repo, name: branch_name) }
      let(:ref) { "refs/heads/#{branch_name}" }

      context 'on master' do
        let(:branch_name) { 'master' }

        it 'imports the branch' do
          subject.import

          expect(Branch).to have_received(:import).with(payload, repo)
        end

        it 'updates merged tickets on repo' do
          subject.import

          expect(repo).to have_received(:update_merged_tickets)
        end

        it 'doesn\'t set ticket on branch' do
          expect {
            subject.import
          }.not_to change { branch.reload.ticket_id }
        end
      end

      context 'on feature branch' do
        let(:branch_name) { 'feature/#123-some-feature' }

        it 'imports the branch' do
          subject.import

          expect(Branch).to have_received(:import).with(payload, repo)
        end

        it 'doesn\'t update merged tickets on repo' do
          subject.import

          expect(repo).not_to have_received(:update_merged_tickets)
        end

        context 'when matching ticket exists' do
          let!(:ticket) { create(:ticket, repo: repo, remote_number: '123') }

          it 'sets ticket on branch' do
            expect {
              subject.import
            }.to change { branch.reload.ticket_id }.from(nil).to(ticket.id)
          end

          it 'marks ticket as unmerged' do
            subject.import

            expect(ticket.reload).not_to be_merged
          end
        end
      end
    end
  end
end
