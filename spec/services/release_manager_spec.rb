require 'rails_helper'

RSpec.describe ReleaseManager, type: :service do
  subject { described_class.new(board, repo) }

  describe '#open_pr?' do
    let(:repo) { create(:repo) }
    let(:board) { create(:board, repos: [repo]) }

    before do
      stub_request(
        :get, 'https://api.github.com/repos/user/repo_name/pulls?per_page=100'
      ).to_return(status: 200, body: body, headers: {})
    end

    context 'when there are no PRs open to master' do
      let(:body) { [] }

      it 'returns false' do
        expect(subject.open_pr?).to be(false)
      end
    end

    context 'when there is an open PR to master' do
      let(:body) do
        [
          base: {
            ref: 'master'
          }
        ]
      end

      it 'returns true' do
        expect(subject.open_pr?).to be(true)
      end
    end
  end

  describe 'create_release' do
    include_context 'board with swimlanes'

    let(:deploying) { create(:swimlane, name: 'Deploying', board: board, position: 2) }

    def self.create_ticket(name)
      let(name) { create(:ticket, repo: repo, remote_title: name) }
    end

    create_ticket(:unmerged_ticket_1)
    create_ticket(:unmerged_ticket_2)
    create_ticket(:merged_ticket)
    create_ticket(:ticket_without_branch)
    create_ticket(:non_deploying_ticket)
    let(:unmerged_tickets) { [unmerged_ticket_1, unmerged_ticket_2] }

    let(:master_sha) { SecureRandom.hex(20) }
    let(:release_branch_name) { Time.now.strftime('release/%Y%m%d-%H%M%S') }

    def branch_name(ticket)
      "feature/##{ticket.remote_number}-#{ticket.remote_title.parameterize}"
    end

    def stub_get(path, status: 200)
      response = block_given? ? yield.to_json : ''

      stub_request(:get, "https://api.github.com/repos/#{remote_url}/#{path}")
        .with(query: hash_including({}))
        .and_return(status: status, headers: { 'Content-Type' => 'application/json' }, body: response)
    end

    def stub_post(path, body, status: 201)
      response = block_given? ? yield.to_json : ''

      stub_request(:post, "https://api.github.com/repos/#{remote_url}/#{path}")
        .with(body: body)
        .and_return(status: status, headers: { 'Content-Type' => 'application/json' }, body: response)
    end

    def have_sent_message(title, attachments = a_hash_including(:attachments))
      have_received(:notify).with(title, attachments)
    end

    before do
      board.update_attributes!(deploy_swimlane: deploying, additional_branches_regex: '^configuration_changes$')

      [*unmerged_tickets, merged_ticket, ticket_without_branch].each do |ticket|
        board.board_tickets.create!(swimlane: deploying, ticket: ticket)
      end

      board.board_tickets.create!(swimlane: dev, ticket: non_deploying_ticket)

      stub_get('branches') do
        [
          { name: 'master' },
          { name: 'configuration_changes' },
          *unmerged_tickets.map { |ticket| { name: branch_name(ticket) } },
          { name: branch_name(non_deploying_ticket) }
        ]
      end

      unmerged_tickets.each do |ticket|
        stub_get("compare/master...#{URI.escape branch_name(ticket)}") do
          { total_commits: 2 }
        end
      end

      stub_get("compare/master...#{URI.escape branch_name(non_deploying_ticket)}") do
        { total_commits: 2 }
      end

      stub_get('git/refs/heads/master') { { object: { sha: master_sha } } }

      allow(SlackNotifier).to receive(:new).and_return(slack_notifier)
    end

    let(:slack_notifier) { double('SlackNotifier', notify: true) }

    let!(:branch_request) do
      stub_post('git/refs', ref: "refs/heads/#{release_branch_name}", sha: master_sha)
    end

    around do |example|
      # Make it easier to match against release branch name
      Timecop.freeze { example.run }
    end

    context 'with no conflicts' do
      let!(:ticket_merge_requests) do
        unmerged_tickets.map do |ticket|
          stub_post('merges', hash_including(base: release_branch_name, head: branch_name(ticket)))
        end
      end

      let!(:additional_branch_merge_request) do
        stub_post('merges', hash_including(base: release_branch_name, head: 'configuration_changes'))
      end

      let!(:pr_request) do
        stub_post('pulls', hash_including(base: 'master', head: release_branch_name)) do
          { html_url: "https://github.com/#{remote_url}/pulls/1" }
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
        stub_post('merges', hash_including(base: release_branch_name, head: branch_name(unmerged_ticket_1)))
      end

      let!(:unsuccessful_merge_request) do
        stub_post(
          'merges', hash_including(base: release_branch_name, head: branch_name(unmerged_ticket_2)),
          status: 409
        ) { { message: 'Merge Conflict' } }
      end

      let!(:additional_branch_merge_request) do
        stub_post('merges', hash_including(base: release_branch_name, head: 'configuration_changes'))
      end

      let!(:pr_request) do
        params = hash_including(
          base: 'master',
          head: release_branch_name,
          title: /(CONFLICTS)/i,
          body: /could not merge all branches/i
        )

        stub_post('pulls', params) do
          { html_url: "https://github.com/#{remote_url}/pulls/1" }
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
  end
end
