FactoryBot.define do
  factory :pull_request_review do
    sequence(:remote_id, 10_000_000)
    remote_pull_request_id { generate(:pr_remote_id) }
    state 'changes_requested'
    sha { generate(:sha) }
    sequence(:url) {|n| "https://github.com/user/repo/pulls/#{n}#pullrequestreview=#{remote_id}" }
    reviewer_remote_id { generate(:user_id) }
    reviewer_username 'baxterthehacker'
    remote_created_at { 10.minutes.ago }
  end
end
