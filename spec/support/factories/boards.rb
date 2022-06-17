FactoryBot.define do
  factory :board do
    transient do
      swimlane_names { [] }
    end

    name { 'My Board' }
    slack_channel { '#general' }

    after(:create) do |board, evaluator|
      evaluator.swimlane_names.each_with_index do |name, index|
        create(:swimlane, board: board, name: name, position: index + 1)
      end
    end
  end
end
