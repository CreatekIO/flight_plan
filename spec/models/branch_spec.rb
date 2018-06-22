require 'rails_helper'

RSpec.describe Branch, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:repo) }
    it { is_expected.to belong_to(:ticket) }
  end

  describe 'attributes' do
    describe 'branch names' do
      it 'strips off prefix when writing branch name' do
        aggregate_failures do
          expect(described_class.new(name: 'refs/heads/master').name).to eq('master')
          expect(described_class.new(base_ref: 'refs/heads/master').base_ref).to eq('master')
        end
      end

      it 'strips off prefix when used in WHERE clause' do
        branch = create(:branch, name: 'develop', base_ref: 'master', repo: create(:repo))

        aggregate_failures do
          expect(described_class.find_by(name: 'refs/heads/develop')).to eq(branch)
          expect(described_class.find_by(name: 'develop')).to eq(branch)

          expect(described_class.find_by(base_ref: 'refs/heads/master')).to eq(branch)
          expect(described_class.find_by(base_ref: 'master')).to eq(branch)
        end
      end
    end
  end
end
