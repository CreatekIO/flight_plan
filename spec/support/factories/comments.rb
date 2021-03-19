FactoryBot.define do
  factory :comment do
    sequence(:remote_id, 70_000_000)
    author_username { 'jsmith' }
    body { 'text' }
  end
end
