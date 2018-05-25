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
  let(:feature_branch_name_1) { "origin/feature/##{remote_no_1}-some-text" }
  let(:feature_branch_name_2) { "origin/feature/##{remote_no_2}-anything" }
  let(:release_branch_name) { 'release/20180518-101500' }
  let(:remote_no_1) { ticket_1.remote_number }
  let(:remote_no_2) { ticket_2.remote_number }
  let(:remote_branch_names) {
    [
      { name: 'origin/master' },
      { name: feature_branch_name_1 },
      { name: feature_branch_name_2 }
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
  let(:pull_request_1_params) {
    {
      base: 'master',
      head: release_branch_name,
      title: release_branch_name,
      body: "**Issues**\nConnects ##{remote_no_1} - Issue No. #{remote_no_1}"
    }
  }
  let(:pull_request_2_params) {
    {
      base: 'master',
      head: release_branch_name,
      title: release_branch_name,
      body: "**Issues**\nConnects ##{remote_no_2} - Issue No. #{remote_no_2}"
    }
  }
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
      stub_gh_diff_feature_branch_to_master("feature/%23#{remote_no_1}-some-text")
      stub_gh_diff_feature_branch_to_master("feature/%23#{remote_no_2}-anything")
      stub_gh_get_master_sha
      stub_gh_create_release_branch
      stub_gh_merge_feature_branch(feature_branch_name_1)
      stub_gh_merge_feature_branch(feature_branch_name_2)
      stub_gh_create_pull_request(pull_request_1_params)
      stub_gh_create_pull_request(pull_request_2_params)
      stub_slack_message

      # fix date/time to ensure release branch name matches
      Timecop.freeze(time_of_release) do
        post path, params: release_params, headers: api_headers
      end

      expect(response).to have_http_status(:created)
      expect(json['release']['repo_releases'].length).to eq(2)
      expect(
        json['release']['repo_releases'].first['board_tickets'].first
      ).to include(
        'id' => board_ticket_1.id,
        'ticket_id' => board_ticket_1.ticket_id
      )
    end
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
      "https://api.github.com/repos/user/repo_name/compare/master...origin/#{branch}"
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
      head: feature_branch_name,
      commit_message: "Merging #{feature_branch_name} into release",
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

  def stub_gh_create_pull_request(pull_request_params)
    stub_request(
      :post,
      'https://api.github.com/repos/user/repo_name/pulls'
    ).with(
      body: pull_request_params
    ).to_return(
      body: pull_request_response.to_json,
      headers: application_json
    )
  end

  def stub_slack_message
    stub_request(:post, 'https://slack.com/api/chat.postMessage')
  end
end
