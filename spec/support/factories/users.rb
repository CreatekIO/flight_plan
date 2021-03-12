FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "username_#{n}" }
    sequence(:name) { |n| "user_#{n}" }
    uid { generate(:user_id) }
    provider { 'github' }
  end
end
