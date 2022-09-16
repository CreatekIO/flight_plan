FactoryBot.define do
  factory :branch_head do
    head_sha { generate(:sha) }
    previous_head_sha { generate(:sha) }
    commits_in_push { rand(1..10) }
    commit_timestamp { Time.now }
    author_username { 'baxterthehacker' }
    committer_username { author_username }
    pusher_remote_id { generate(:user_id) }
    pusher_username { author_username }
  end
end
