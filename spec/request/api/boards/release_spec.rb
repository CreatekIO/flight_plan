require 'rails_helper'

RSpec.describe 'Releases', type: :request do
  include_context 'api'
  let(:path) { "/api/boards/#{board.id}/releases" }
  let(:board) { create(:board, repos: [repo_1, repo_2]) }
  let(:repo_1) { create(:repo) }
  let(:repo_2) { create(:repo) }
  let(:ticket_1) { create(:ticket, repo: repo_1) }
  let(:ticket_2) { create(:ticket, repo: repo_2) }
  let(:swimlane) { create(:swimlane, board: board) }
  let!(:board_ticket_1) { create(:board_ticket, board: board, ticket: ticket_1, swimlane: swimlane) }
  let!(:board_ticket_2) { create(:board_ticket, board: board, ticket: ticket_2, swimlane: swimlane) }

  let(:application_json) { { 'Content-Type' => 'application/json' } }
  let(:feature_branch_name_1) { "feature/##{remote_no_1}-some-text" }
  let(:feature_branch_name_2) { "feature/##{remote_no_2}-anything" }
  let(:release_branch_name) { 'release/20180518-101500' }
  let(:remote_no_1) { ticket_1.remote_number }
  let(:remote_no_2) { ticket_2.remote_number }
  let(:remote_branch_names) {
    [
      { name: 'origin/master' },
      { name: "origin/#{feature_branch_name_1}" },
      { name: "origin/#{feature_branch_name_2}" }
    ]
  }
  let(:release_params) { { release: { title: 'new release' } } }
  let(:remote_commits) { { total_commits: 1 } }
  let(:remote_master) { { object: { sha: master_sha } } }
  let(:create_branch_params) {
    {
      ref: "refs/heads/#{release_branch_name}",
      sha: master_sha
    }
  }
  let(:master_sha) { 'cafe8080' }
  let(:pull_request_response) {
    { html_url: 'https://fake.example.com/pull/1' }
  }
  let(:time_of_release) { Time.local(2018, 5, 18, 10, 15, 0) }

  before do
    board.update(deploy_swimlane: swimlane)
  end

  describe 'POST' do
    it 'creates a release' do
      stub_gh_remote_branches
      stub_gh_diff_feature_branch_to_master(feature_branch_name_1)
      stub_gh_diff_feature_branch_to_master(feature_branch_name_2)
      stub_gh_get_master_sha
      stub_gh_create_release_branch
      stub_gh_merge_feature_branch(feature_branch_name_1)
      stub_gh_merge_feature_branch(feature_branch_name_2)
      stub_gh_create_pull_request(ticket_1)
      stub_gh_create_pull_request(ticket_2)
      stub_slack_message

      # fix date/time to ensure release branch name matches
      Timecop.freeze(time_of_release) do
        post path, params: release_params, headers: api_headers
      end

      expect(response).to have_http_status(:created)
      repo_releases = json['release']['repo_releases']
      board_ticket = repo_releases.first['board_tickets'].first
      expect(repo_releases.length).to eq(2)
      expect(
        repo_releases.first['board_tickets'].first
      ).to include(
        'id' => board_ticket_1.id
      )
      expect(repo_releases.first['board_tickets'].first['ticket']).to include(
        'id' => board_ticket_1.ticket_id,
        'remote_title' => board_ticket_1.ticket.remote_title,
        'remote_number' => board_ticket_1.ticket.remote_number
      )
    end

    context 'when a single repo_id is provided' do
      let(:release_params) {
        {
          release: {
            title: 'new release',
            repo_ids: [ repo_1.id ]
          }
        }
      }
      it 'only creates a release for that repo' do
        stub_gh_remote_branches
        stub_gh_diff_feature_branch_to_master(feature_branch_name_1)
        stub_gh_get_master_sha
        stub_gh_create_release_branch
        stub_gh_merge_feature_branch(feature_branch_name_1)
        stub_gh_create_pull_request(ticket_1)
        stub_slack_message

        Timecop.freeze(time_of_release) do
          post path, params: release_params, headers: api_headers
        end

        expect(response).to have_http_status(:created)
        expect(json['release']['repo_releases'].length).to eq(1)
      end
    end
  end

  def pull_request_params(ticket)
    {
      base: 'master',
      head: release_branch_name,
      title: release_branch_name,
      body: "**Issues**\nConnects ##{ticket.remote_number} - #{ticket.remote_title}"
    }
  end

  def stub_gh_remote_branches
    stub_request(
      :get,
      'https://api.github.com/repos/user/repo_name/branches?per_page=100'
    ).to_return(
      status: :ok,
      body: remote_branch_names
    )
  end

  def stub_gh_diff_feature_branch_to_master(branch)
    stub_request(
      :get,
      "https://api.github.com/repos/user/repo_name/compare/master...origin/#{URI::encode(branch)}"
    ).to_return(
      status: :ok,
      body: remote_commits.to_json,
      headers: application_json
    )
  end

  def stub_gh_get_master_sha
    stub_request(
      :get,
      'https://api.github.com/repos/user/repo_name/git/refs/heads/master?per_page=100'
    ).to_return(
      status: :ok,
      body: remote_master.to_json,
      headers: application_json
    )
  end

  def stub_gh_create_release_branch
    stub_request(
      :post,
      'https://api.github.com/repos/user/repo_name/git/refs'
    ).with(
      body: create_branch_params.to_json
    ).to_return(
      status: :ok,
      headers: application_json
    )
  end

  def stub_gh_merge_feature_branch(feature_branch_name)
    merge_params = {
      base: release_branch_name,
      head: "origin/#{feature_branch_name}",
      commit_message: "Merging origin/#{feature_branch_name} into release"
    }
    stub_request(
      :post,
      'https://api.github.com/repos/user/repo_name/merges'
    ).with(
      body: merge_params
    ).to_return(
      status: :ok
    )
  end

  def stub_gh_create_pull_request(ticket)
    stub_request(
      :post,
      'https://api.github.com/repos/user/repo_name/pulls'
    ).with(
      body: pull_request_params(ticket)
    ).to_return(
      body: pull_request_response.to_json,
      headers: application_json
    )
  end

  def stub_slack_message
    stub_request(:post, 'https://slack.com/api/chat.postMessage')
  end
end
