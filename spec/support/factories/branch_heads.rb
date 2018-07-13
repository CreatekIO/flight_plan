FactoryBot.define do
  factory :branch_head do
    head_sha { SecureRandom.hex(20) }
    previous_head_sha { SecureRandom.hex(20) }
    commits_in_push { rand(1..10) }
    commit_timestamp { Time.now }
    author_username 'baxterthehacker'
    committer_username { author_username }
    pusher_remote_id { generate(:user_id) }
    pusher_username { author_username }

    trait :with_head do
      after(:build) do |branch|
        branch_head = build(:branch_head)

        branch.heads << branch_head
        branch.latest_head = branch_head
      end
    end
  end
end
