RSpec.shared_context 'board with swimlanes' do
  let(:repo) { create(:repo, slug: slug) }
  let(:slug) { 'org_name/repo_name' }
  let(:board) { create(:board, repos: [ repo ]) }
  let!(:backlog) { create(:swimlane, name: 'Backlog', board: board, position: 1) }
  let!(:dev) { create(:swimlane, name: 'Dev', board: board, position: 2) }
  let!(:closed) { create(:swimlane, name: 'Closed', board: board, position: 3) }
end
