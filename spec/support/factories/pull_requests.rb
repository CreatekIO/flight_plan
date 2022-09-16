FactoryBot.define do
  factory :pull_request do
    number { generate(:pr_number) }
    remote_id { generate(:pr_remote_id) }
    title { "Pull Request No. #{number}" }
    state { 'open' }
    head_branch { "feature/#{number}-test" }
    head_sha { generate(:sha) }
    base_branch { 'develop' }

    trait :merged do
      state { 'closed' }
      merged { true }
    end
  end
end
