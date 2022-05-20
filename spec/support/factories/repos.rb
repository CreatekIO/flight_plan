FactoryBot.define do
  factory :repo do
    sequence(:name) { |n| "Repo #{n}" }
    sequence(:slug) { |n| "user/repo_name_#{n}" }
    deployment_branch { 'master' }
    remote_id { generate(:repo_id) }

    trait :uses_app do
      remote_installation_id { generate(:github_id) }
    end
  end
end

