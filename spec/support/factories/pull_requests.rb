FactoryGirl.define do
  factory :pull_request do
    # Generates even numbers
    sequence(:remote_number, 2.step(Float::INFINITY, 2).lazy)
    remote_title { "Pull Request No. #{remote_number}" }
    remote_state 'open'
    remote_head_branch { "feature/#{remote_number}-test" }
    remote_head_sha { SecureRandom.hex(20) }
    remote_base_branch 'develop'
  end
end
