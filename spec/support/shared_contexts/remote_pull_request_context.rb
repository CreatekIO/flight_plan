RSpec.shared_context 'remote pull request' do
  let(:remote_url) { 'org_name/repo_name' }
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
        sha: SecureRandom.hex(20)
      },
      base: {
        ref: 'master',
        sha: SecureRandom.hex(20)
      }
    }
  }

  let(:remote_repo) {
    {
      full_name: remote_url
    }
  }
end
