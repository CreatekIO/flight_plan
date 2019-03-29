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
          id: issue_id * 100,
          name: 'status: dev',
          color: 'ff0000'
        }
      ],
      milestone: {
        id: issue_id * 200,
        title: 'Q2 targets',
        description: 'Things to hit in Q2',
        state: 'open',
        due_on: 2.months.from_now.utc.iso8601
      }
    }
  }

  let(:remote_repo) {
    {
      full_name: remote_url
    }
  }
end
