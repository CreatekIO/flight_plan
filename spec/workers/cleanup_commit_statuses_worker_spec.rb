require 'rails_helper'

RSpec.describe CleanupCommitStatusesWorker do
  include_context 'commit statuses'

  before do
    # Silence logger
    allow(Sidekiq).to receive(:logger).and_return(double.as_null_object)
  end

  after(:context) do
    # Clean up once we've finished this test file
    CommitStatus.delete_all
    Repo.delete_all
  end

  describe '#perform' do
    generate_scenario :failed_commit, <<~TXT
      pending
      pending +1
      pending +2
      failure +3
    TXT

    generate_scenario :passed_commit, <<~TXT
      pending
      pending +1
      pending +2
      success +3
    TXT

    generate_scenario :different_services_commit, <<~TXT
      pending  0 circleci
      pending  0 dockercloud
      pending +1 circleci
      success +2 circleci
      failure +2 dockercloud
    TXT

    generate_scenario :only_one_pending_commit, <<~TXT
      pending
    TXT

    generate_scenario :in_progress_commit, <<~TXT
      pending
      pending +1
    TXT

    generate_scenario :restarted_commit, <<~TXT
      pending
      failure +1
      pending +2
    TXT

    generate_scenario :flaky_commit, <<~TXT
      pending
      pending +1
      failure +2
      pending +3
      pending +4
      failure +5
      pending +6
      pending +7
      success +8
    TXT

    generate_scenario :different_repos_commit, <<~TXT
      success  0 circleci repo_a
      success +1 circleci repo_b
    TXT

    before do
      # Allow records to persist between examples, since we create all
      # objects up-front (to more mimic a production-like scenario where
      # we have statuses for many commits), but we test each scenario in
      # a separate example for clarity
      CommitStatus.connection.commit_transaction
    end

    context 'with failing commit' do
      it 'removes all but latest (failing) status' do
        subject.perform

        aggregate_failures do
          expect(failed_commit.statuses[0..2]).to all be_destroyed
          expect(failed_commit.statuses.last).to be_present.and be_failure
        end
      end
    end

    context 'with passing commit' do
      it 'removes all but latest (passing) status' do
        subject.perform

        aggregate_failures do
          expect(passed_commit.statuses[0..2]).to all be_destroyed
          expect(passed_commit.statuses.last).to be_present.and be_success
        end
      end
    end

    context 'with differing statuses from two services' do
      it 'retains latest status from each service, and deletes the rest' do
        subject.perform

        aggregate_failures do
          expect(different_services_commit.statuses[0..2]).to all be_destroyed
          expect(different_services_commit.statuses[3]).to have_attributes(
            present?: true,
            state: 'success',
            context: 'circleci'
          )
          expect(different_services_commit.statuses[4]).to have_attributes(
            present?: true,
            state: 'failure',
            context: 'dockercloud'
          )
        end
      end
    end

    context 'with a single pending status' do
      it 'retains the status' do
        subject.perform

        expect(only_one_pending_commit.statuses.first).to be_present
      end
    end

    context 'with in-progress commit' do
      it 'only retains latest (pending) status' do
        subject.perform

        aggregate_failures do
          expect(in_progress_commit.statuses.first).to be_destroyed
          expect(in_progress_commit.statuses.second).to have_attributes(present?: true, state: 'pending')
        end
      end
    end

    context 'with failed and then in-progress (restarted) commit' do
      it 'retains latest (pending) status and old failed status' do
        subject.perform

        aggregate_failures do
          expect(restarted_commit.statuses.first).to be_destroyed
          expect(restarted_commit.statuses.second).to have_attributes(present?: true, state: 'failure')
          expect(restarted_commit.statuses.last).to have_attributes(present?: true, state: 'pending')
        end
      end
    end

    context 'with flaky commit' do
      it 'only retains non-pending statuses' do
        subject.perform

        aggregate_failures do
          expect(flaky_commit.statuses[0..1]).to all be_destroyed
          expect(flaky_commit.statuses[2]).to have_attributes(present?: true, state: 'failure')
          expect(flaky_commit.statuses[3..4]).to all be_destroyed
          expect(flaky_commit.statuses[5]).to have_attributes(present?: true, state: 'failure')
          expect(flaky_commit.statuses[6..7]).to all be_destroyed
          expect(flaky_commit.statuses[8]).to have_attributes(present?: true, state: 'success')
        end
      end
    end

    context 'with statuses on same SHA but different repos' do
      it 'retains statuses from each repo' do
        subject.perform

        expect(different_repos_commit.statuses).to all be_present
      end
    end
  end
end
