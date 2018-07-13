FactoryBot.define do
  factory :pull_request do
    remote_number { generate(:pr_number) }
    remote_id { generate(:pr_remote_id) }
    remote_title { "Pull Request No. #{remote_number}" }
    remote_state 'open'
    remote_head_branch { "feature/#{remote_number}-test" }
    remote_head_sha { generate(:sha) }
    remote_base_branch 'develop'
  end
end
