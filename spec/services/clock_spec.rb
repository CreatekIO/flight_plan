require 'rails_helper'

RSpec.describe Clockwork do
  before { Clockwork::Test.clear! }

  let(:clock_file) { Rails.root.join('clock.rb') }
  let(:time_window) { Date.today.next_weekday.all_day }

  before do
    if defined?(early_deploy_boards)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('EARLY_DEPLOY_BOARD_IDS').and_return(
        early_deploy_boards.map(&:id).join(',').presence
      )
    end

    Clockwork::Test.run(
      start_time: time_window.begin,
      end_time: time_window.end,
      tick_speed: 5.minutes,
      file: clock_file
    )
  end

  describe 'schedule' do
    subject(:clockwork) { Clockwork::Test }

    context 'a weekday' do
      let(:time_window) { Date.today.next_weekday.all_day }

      it { should have_run('auto_deploy').once }
      it { should have_run('auto_merge').once }
    end

    context 'a weekend' do
      let(:time_window) { Date.today.next_occurring(:saturday).all_day }

      it { should_not have_run('auto_deploy') }
      it { should_not have_run('auto_merge') }
    end
  end

  def create_board(with_auto_deploy_repos:, with_tickets_to_deploy: false)
    create(
      :board,
      repos: [create(:repo, auto_deploy: with_auto_deploy_repos)],
      swimlane_names: ['Backlog', 'Dev', 'Deploying', 'Deployed']
    ).tap do |board|
      deploy_swimlane = board.swimlanes.find_by!(name: 'Deploying')
      board.update_attributes!(deploy_swimlane: deploy_swimlane)

      if with_tickets_to_deploy
        create(
          :board_ticket,
          board: board,
          swimlane: deploy_swimlane,
          ticket: create(:ticket, repo: board.repos.first)
        )
      end
    end
  end

  context 'auto deploy jobs' do
    let!(:boards_with_tickets_to_deploy) do
      Array.new(2) { create_board(with_auto_deploy_repos: true, with_tickets_to_deploy: true) }
    end

    let!(:boards_with_tickets_to_deploy_early) do
      Array.new(2) { create_board(with_auto_deploy_repos: true, with_tickets_to_deploy: true) }
    end

    let!(:other_early_deploy_boards) do
      [
        create_board(with_auto_deploy_repos: false, with_tickets_to_deploy: true),
        create_board(with_auto_deploy_repos: true, with_tickets_to_deploy: false),
        create_board(with_auto_deploy_repos: false, with_tickets_to_deploy: false)
      ]
    end

    let(:early_deploy_boards) { boards_with_tickets_to_deploy_early + other_early_deploy_boards }

    before do
      create_board(with_auto_deploy_repos: false, with_tickets_to_deploy: true)
      create_board(with_auto_deploy_repos: true, with_tickets_to_deploy: false)
      create_board(with_auto_deploy_repos: false, with_tickets_to_deploy: false)
    end

    describe 'auto_deploy' do
      subject { Clockwork::Test.block_for('auto_deploy') }

      it 'enqueues deploy workers for boards with tickets to deploy' do
        subject.call

        board_ids = DeployWorker.jobs.map { |job| job['args'].first }
        expected_board_ids = boards_with_tickets_to_deploy.map(&:id)

        expect(board_ids).to match_array(expected_board_ids)
      end

      context 'no early-deploy boards' do
        let(:early_deploy_boards) { [] }

        it 'enqueues deploy workers for all boards with tickets to deploy' do
          subject.call

          board_ids = DeployWorker.jobs.map { |job| job['args'].first }
          expected_board_ids = (
            boards_with_tickets_to_deploy + boards_with_tickets_to_deploy_early
          ).map(&:id)

          expect(board_ids).to match_array(expected_board_ids)
        end
      end
    end

    describe 'auto_deploy_early' do
      subject { Clockwork::Test.block_for('auto_deploy_early') }

      it 'enqueues deploy workers for early-deploy boards with tickets to deploy' do
        subject.call

        board_ids = DeployWorker.jobs.map { |job| job['args'].first }
        expected_board_ids = boards_with_tickets_to_deploy_early.map(&:id)

        expect(board_ids).to match_array(expected_board_ids)
      end

      context 'no early-deploy boards' do
        let(:early_deploy_boards) { [] }

        it 'does\'t enqueue any deploy workers' do
          expect { subject.call }.not_to change { DeployWorker.jobs }
        end
      end
    end
  end

  describe 'auto_merge' do
    let!(:boards_with_auto_deploy_repos) do
      Array.new(2) { create_board(with_auto_deploy_repos: true) }
    end

    let!(:board_without_auto_deploy_repos) do
      create_board(with_auto_deploy_repos: false)
    end

    subject { Clockwork::Test.block_for('auto_merge') }

    it 'enqueues merge worker for all boards with auto-deploy repos' do
      subject.call

      board_ids = MergeWorker.jobs.map { |job| job['args'].first }
      expected_board_ids = boards_with_auto_deploy_repos.map(&:id)

      expect(board_ids).to match_array(expected_board_ids)
    end
  end
end
