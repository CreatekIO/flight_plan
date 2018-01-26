require 'rails_helper'
RSpec.describe ReleaseManager, type: :service do
  describe '#open_pr?' do
    subject{ ReleaseManager.new(board, repo) }
    let(:repo) { create(:repo) }
    let(:board) { create(:board, repos: [ repo ]) }
    before do
      stub_request(
        :get, "https://api.github.com/repos/user/repo_name/pulls?per_page=100"
      ).to_return(status: 200, body: body, headers: {})
    end
    context 'when there are no PRs open to master' do
      let(:body) { [ ] }
      it 'returns false' do
        expect(subject.open_pr?).to be(false)
      end
    end

    context 'when there is an open PR to master' do
      let(:body) {
        [
          base: {
            ref: 'master'
          }
        ]
      }
      it 'returns true' do
        expect(subject.open_pr?).to be(true)
      end
    end
  end
end
