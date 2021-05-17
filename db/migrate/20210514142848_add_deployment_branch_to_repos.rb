class AddDeploymentBranchToRepos < ActiveRecord::Migration[5.2]
  class Repo < ActiveRecord::Base; end

  def change
    add_column :repos, :deployment_branch, :string

    say_with_time 'Setting repos.deployment_branch for existing rows to `master`' do
      Repo.update_all(deployment_branch: 'master')
    end
  end
end
