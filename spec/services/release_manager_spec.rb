require 'rails_helper'

RSpec.describe ReleaseManager, type: :service do
  subject { described_class.new(board, repo) }

  before { stub_slack }

  describe '#open_pr?' do
    let(:repo) { create(:repo, deployment_branch: 'main') }
    let(:board) { create(:board, repos: [repo]) }
    let(:slug) { repo.slug }

    before do
      stub_gh_get('pulls') { body }
    end

    context 'when there are no PRs open to Repo#deployment_branch' do
      let(:body) { [] }

      it 'returns false' do
        expect(subject.open_pr?).to be(false)
      end
    end

    context 'when there is an open non-release PR to Repo#deployment_branch' do
      let(:body) do
        [
          base: { ref: repo.deployment_branch },
          head: { ref: 'hotfix/fix-bugs' }
        ]
      end

      it 'returns false' do
        expect(subject.open_pr?).to be(false)
      end
    end

    context 'when there is an open release PR to Repo#deployment_branch' do
      let(:body) do
        [
          base: { ref: repo.deployment_branch },
          head: { ref: 'release/20180102-103000' }
        ]
      end

      it 'returns true' do
        expect(subject.open_pr?).to be(true)
      end
    end
  end

  describe 'create_release' do
    include_context 'board with swimlanes'

    let(:repo) { create(:repo, slug: slug, deployment_branch: 'main') }
    let(:deploying) { create(:swimlane, name: 'Deploying', board: board, position: 2) }

    def self.create_ticket(name)
      let(name) { create(:ticket, repo: repo, title: name) }
    end

    create_ticket(:unmerged_ticket_1)
    create_ticket(:unmerged_ticket_2)
    create_ticket(:merged_ticket)
    create_ticket(:ticket_without_branch)
    create_ticket(:non_deploying_ticket)
    let(:unmerged_tickets) { [unmerged_ticket_1, unmerged_ticket_2] }

    let(:deployment_branch_head_sha) { SecureRandom.hex(20) }
    let(:release_branch_name) { Time.now.strftime('release/%Y%m%d-%H%M%S') }

    def branch_name(ticket)
      "feature/##{ticket.number}-#{ticket.title.parameterize}"
    end

    before do
      board.update!(deploy_swimlane: deploying, additional_branches_regex: '^configuration_changes$')

      [*unmerged_tickets, merged_ticket, ticket_without_branch].each do |ticket|
        board.board_tickets.create!(swimlane: deploying, ticket: ticket)
      end

      board.board_tickets.create!(swimlane: dev, ticket: non_deploying_ticket)

      stub_gh_get('branches') do
        [
          { name: repo.deployment_branch },
          { name: 'configuration_changes' },
          *unmerged_tickets.map { |ticket| { name: branch_name(ticket) } },
          { name: branch_name(non_deploying_ticket) }
        ]
      end

      unmerged_tickets.each do |ticket|
        stub_gh_get("compare/#{repo.deployment_branch}...#{CGI.escape branch_name(ticket)}") do
          { total_commits: 2 }
        end
      end

      stub_gh_get("compare/#{repo.deployment_branch}...#{CGI.escape branch_name(non_deploying_ticket)}") do
        { total_commits: 2 }
      end

      stub_gh_get("git/refs/heads/#{repo.deployment_branch}") do
        { object: { sha: deployment_branch_head_sha } }
      end
    end

    let!(:branch_request) do
      stub_gh_post('git/refs', ref: "refs/heads/#{release_branch_name}", sha: deployment_branch_head_sha)
    end

    around do |example|
      # Make it easier to match against release branch name
      freeze_time { example.run }
    end

    context 'with no conflicts' do
      let!(:ticket_merge_requests) do
        unmerged_tickets.map do |ticket|
          stub_gh_post('merges', hash_including(base: release_branch_name, head: branch_name(ticket)))
        end
      end

      let!(:additional_branch_merge_request) do
        stub_gh_post('merges', hash_including(base: release_branch_name, head: 'configuration_changes'))
      end

      let!(:pr_request) do
        stub_gh_post('pulls', hash_including(base: repo.deployment_branch, head: release_branch_name)) do
          { html_url: "https://github.com/#{slug}/pulls/1" }
        end
      end

      it 'creates a release' do
        subject.create_release

        aggregate_failures do
          expect(branch_request).to have_been_requested
          expect(ticket_merge_requests).to all have_been_requested
          expect(additional_branch_merge_request).to have_been_requested
          expect(pr_request).to have_been_requested

          expect(slack_notifier).to have_sent_message(/pull request created/i)
        end
      end
    end

    context 'with a conflict' do
      let!(:successful_merge_request) do
        stub_gh_post('merges', hash_including(base: release_branch_name, head: branch_name(unmerged_ticket_1)))
      end

      let!(:unsuccessful_merge_request) do
        stub_gh_post(
          'merges', hash_including(base: release_branch_name, head: branch_name(unmerged_ticket_2)),
          status: 409
        ) { { message: 'Merge Conflict' } }
      end

      let!(:additional_branch_merge_request) do
        stub_gh_post('merges', hash_including(base: release_branch_name, head: 'configuration_changes'))
      end

      let!(:pr_request) do
        params = hash_including(
          base: repo.deployment_branch,
          head: release_branch_name,
          title: /(CONFLICTS)/i,
          body: /could not merge all branches/i
        )

        stub_gh_post('pulls', params) do
          { html_url: "https://github.com/#{slug}/pulls/1" }
        end
      end

      it 'creates a release with notice about conflicts' do
        subject.create_release

        aggregate_failures do
          expect(branch_request).to have_been_requested
          expect(successful_merge_request).to have_been_requested
          expect(unsuccessful_merge_request).to have_been_requested
          expect(additional_branch_merge_request).to have_been_requested
          expect(pr_request).to have_been_requested

          expect(slack_notifier).to have_sent_message(/pull request created/i)
        end
      end
    end

    context 'problem creating release PR' do
      before do
        unmerged_tickets.map do |ticket|
          stub_gh_post('merges', hash_including(base: release_branch_name, head: branch_name(ticket)))
        end
        stub_gh_post('merges', hash_including(base: release_branch_name, head: 'configuration_changes'))

        stub_gh_post('pulls', hash_including(base: repo.deployment_branch, head: release_branch_name), status: 503)
      end

      let!(:branch_deletion_request) do
        stub_gh_delete("git/refs/heads/#{release_branch_name}")
      end

      it 'rolls back release' do
        subject.create_release

        aggregate_failures do
          expect(branch_deletion_request).to have_been_requested

          expect(slack_notifier).to have_sent_message(/pull request failed/i)
        end
      end
    end

    context 'all branches conflict' do
      before do
        unmerged_tickets.map do |ticket|
          stub_gh_post(
            'merges', hash_including(base: release_branch_name, head: branch_name(ticket)),
            status: 409
          ) { { message: 'Merge Conflict' } }
        end

        stub_gh_post(
          'merges', hash_including(base: release_branch_name, head: 'configuration_changes'),
          status: 409
        ) { { message: 'Merge Conflict' } }
      end

      let!(:pr_request) do
        stub_gh_post('pulls', hash_including(base: repo.deployment_branch, head: release_branch_name), status: 422) do
          { message: "No commits between #{repo.deployment_branch} and #{release_branch_name}" }
        end
      end

      let!(:branch_deletion_request) do
        stub_gh_delete("git/refs/heads/#{release_branch_name}")
      end

      it 'rolls back release without trying to create PR' do
        subject.create_release

        aggregate_failures do
          expect(branch_deletion_request).to have_been_requested
          expect(pr_request).not_to have_been_requested

          expect(slack_notifier).to have_sent_message(/pull request failed/i)
        end
      end
    end
  end

  describe '#merge_prs' do
    let(:repo) { create(:repo, deployment_branch: 'main') }
    let(:board) { create(:board, repos: [repo]) }
    let(:slug) { repo.slug }

    before do
      stub_gh_get('pulls') { body }
    end

    let!(:merge_request) do
      stub_gh_put('pulls/{number}/merge')
    end

    context 'when there are no PRs open to Repo#deployment_branch' do
      let(:body) { [] }

      it 'does not merge anything' do
        subject.merge_prs

        aggregate_failures do
          expect(merge_request).not_to have_been_requested
          expect(slack_notifier).not_to have_received(:notify)
        end
      end
    end

    context 'when there is an open non-release PR to Repo#deployment_branch' do
      let(:body) do
        [
          number: 1,
          title: 'Hotfix',
          base: { ref: repo.deployment_branch },
          head: { ref: 'hotfix/fix-bugs' }
        ]
      end

      it 'does not merge anything' do
        subject.merge_prs

        aggregate_failures do
          expect(merge_request).not_to have_been_requested
          expect(slack_notifier).not_to have_received(:notify)
        end
      end
    end

    context 'when there is an open release PR to Repo#deployment_branch' do
      let(:body) do
        [
          number: 1,
          title: 'Release',
          base: { ref: repo.deployment_branch },
          head: { ref: 'release/20180102-103000' }
        ]
      end

      it 'merges release PR' do
        subject.merge_prs

        aggregate_failures do
          expect(WebMock).to have_requested(:put, expand_gh_url('pulls/1/merge'))
          expect(slack_notifier).to have_sent_message(/pull request merged/i)
        end
      end
    end

    context 'when there is an open release PR with conflicts' do
      let(:body) do
        [
          number: 1,
          title: 'Release (CONFLICTS)',
          base: { ref: repo.deployment_branch },
          head: { ref: 'release/20180102-103000' }
        ]
      end

      it 'does not merge anything' do
        subject.merge_prs

        aggregate_failures do
          expect(merge_request).not_to have_been_requested
          expect(slack_notifier).not_to have_received(:notify)
        end
      end
    end

    context 'when there is an open release PR and another PR' do
      let(:body) do
        [
          {
            number: 1,
            title: 'Hotfix',
            base: { ref: repo.deployment_branch },
            head: { ref: 'hotfix/fix-bugs' }
          },
          {
            number: 2,
            title: 'Release',
            base: { ref: repo.deployment_branch },
            head: { ref: 'release/20180102-103000' }
          }
        ]
      end

      it 'just merges release PR' do
        subject.merge_prs

        aggregate_failures do
          expect(WebMock).not_to have_requested(:put, expand_gh_url('pulls/1/merge'))
          expect(WebMock).to have_requested(:put, expand_gh_url('pulls/2/merge'))

          expect(slack_notifier).to have_sent_message(/pull request merged/i).once
        end
      end
    end
  end
end
