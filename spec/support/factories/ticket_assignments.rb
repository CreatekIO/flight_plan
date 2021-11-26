FactoryBot.define do
  factory :ticket_assignment do
    assignee_remote_id { generate(:user_id) }
    sequence(:assignee_username) { |n| "assignee-#{n}" }
  end
end
