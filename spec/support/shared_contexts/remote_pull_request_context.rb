RSpec.shared_context 'remote pull request' do
  let(:slug) { 'org_name/repo_name' }
  let(:pull_request_id) { 999 }
  let(:pull_request_no) { 3 }
  let(:remote_pull_request) {
    {
      id: pull_request_id,
      number: pull_request_no,
      title: 'pull request title',
      body: 'pull request body',
      state: 'open',
      head: {
        ref: 'feature/#3-issue',
        sha: generate(:sha)
      },
      base: {
        ref: 'master',
        sha: generate(:sha)
      },
      user: {
        id: 1234567,
        login: 'baxterthehacker'
      }
    }
  }

  let(:remote_repo) {
    {
      full_name: slug
    }
  }
end
