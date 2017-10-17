RSpec.shared_context 'remote issue' do
  let(:remote_url) { 'org_name/repo_name' }
  let(:issue_id) { 888 }
  let(:issue_no) { 2 }
  let(:remote_issue) {
    { 
      id: issue_id,
      number: issue_no,
      title: 'issue title',
      body: 'issue body',
      state: 'open',
      labels: [
        {
          name: 'status: dev'
        }
      ]
    }
  }

  let(:remote_repo) {
    {
      full_name: remote_url
    }
  }
end
