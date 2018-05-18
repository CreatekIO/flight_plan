require 'rails_helper'

RSpec.describe 'Releases', type: :request do
  include_context 'api'
  let(:path) { "/api/boards/#{board.id}/releases" }
  let(:board) { create(:board, repos: [repo]) }
  let(:repo) { create(:repo) }
  let(:ticket) { create(:ticket, repo: repo) }
  let(:swimlane) { create(:swimlane, board: board) }
  let!(:board_ticket) { create(:board_ticket, board: board, ticket: ticket, swimlane: swimlane) }

  let(:application_json) { { 'Content-Type' => 'application/json' } }
  let(:feature_branch_name) { "origin/feature/##{remote_no}-some-text" }
  let(:release_branch_name) { 'release/20180518-101500' }
  let(:remote_no) { ticket.remote_number }
  let(:remote_branch_names) {
    [
      { name: 'origin/master' },
      { name: feature_branch_name }
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
  let(:merge_feature_branch_params) {
    {
      base: release_branch_name,
      head: feature_branch_name,
      commit_message: "Merging #{feature_branch_name} into release",
    }
  }
  let(:pull_request_params) {
    {
      base: 'master',
      head: release_branch_name,
      title: release_branch_name,
      body: "**Issues**\nConnects ##{remote_no} - Issue No. #{remote_no}"
    }
  }
  let(:pull_request_response) {
    { html_url: 'https://fake.example.com/pull/1' }
  }

  before do
    board.update(deploy_swimlane: swimlane)
  end

  describe 'POST' do
    it 'creates a release' do
      stub_gh_remote_branches
      stub_gh_diff_feature_branch_to_master
      stub_gh_get_master_sha
      stub_gh_create_release_branch
      stub_gh_merge_feature_branch
      stub_gh_create_pull_request
      stub_slack_message

      # fix date/time to ensure release branch name matches
      Timecop.freeze(Time.local(2018, 5, 18, 10, 15, 0)) do
        post path, params: release_params, headers: api_headers
      end

      expect(response).to have_http_status(:created)
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

  def stub_gh_diff_feature_branch_to_master
    stub_request(
      :get,
      "https://api.github.com/repos/user/repo_name/compare/master...origin/feature/%23#{remote_no}-some-text"
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

  def stub_gh_merge_feature_branch
    stub_request(
      :post,
      'https://api.github.com/repos/user/repo_name/merges'
    ).with(
      body: merge_feature_branch_params
    ).to_return(
      status: :ok
    )
  end

  def stub_gh_create_pull_request
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
