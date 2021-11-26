FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "username-#{n}" }
    sequence(:name) { |n| "User #{n}" }
    uid { generate(:user_id) }
    provider { 'github' }
  end
end
