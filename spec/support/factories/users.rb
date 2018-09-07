FactoryBot.define do
  factory :user do
    sequence(:name) {|n| "user_#{n}" }
    uid { generate(:user_id) }
    provider 'github'
  end
end
