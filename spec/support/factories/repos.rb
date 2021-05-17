FactoryBot.define do
  factory :repo do
    name { 'Repo' }
    slug { 'user/repo_name' }
    deployment_branch { 'master' }
  end
end

