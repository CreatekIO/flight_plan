FactoryBot.define do
  factory :commit_status do
    sequence(:remote_id, 5_000_000_00)
    state 'pending'
    sha { SecureRandom.hex(20) }
    description 'Your tests are running'
    context 'ci/service'
    url { "https://ci.service.test/#{remote_id}" }
    sequence(:author_remote_id, 10_000)
    author_username 'baxterthehacker'
    committer_remote_id { author_remote_id }
    committer_username { author_username }
    remote_created_at { 10.minutes.ago }
  end
end
