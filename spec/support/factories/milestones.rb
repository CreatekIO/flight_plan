FactoryBot.define do
  factory :milestone do
    sequence(:remote_id, 1_000_000)
    sequence(:number)
    title { "Milestone #{number}" }
    state 'open'
  end
end
