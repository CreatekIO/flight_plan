FactoryBot.define do
  factory :branch do
    sequence(:name) {|n| "branch-#{n}" }
    base_ref 'master'

    trait :with_head do
      after(:build) do |branch|
        branch_head = build(:branch_head)

        branch.heads << branch_head
        branch.latest_head = branch_head
      end
    end
  end
end
