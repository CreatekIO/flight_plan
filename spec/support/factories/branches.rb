FactoryBot.define do
  factory :branch do
    transient do
      head { {} }
    end

    sequence(:name) {|n| "branch-#{n}" }
    base_ref { 'master' }

    after(:build) do |branch, evaluator|
      head = evaluator.head

      if head.present?
        head = {} unless head.is_a?(Hash)
        head[:head_sha] = evaluator.head if evaluator.head.is_a?(String)

        branch_head = build(:branch_head, head)

        branch.heads << branch_head
        branch.latest_head = branch_head
      end
    end

    trait :with_head do
      head { true }
    end
  end
end
