require 'rails_helper'
RSpec.describe DeployWorker, type: :worker do
  context 'when there is an existing PR to master' do
    xit 'does not create a release PR' do
    end
  end

  context 'when it\'s outside the working day' do
    xit 'does not create a release PR' do
    end
  end

  context 'when issues are pending deployment' do
    xit 'creates a release PR' do
    end
  end
end
