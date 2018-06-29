FactoryBot.define do
  factory :swimlane do
    board nil
    sequence :name {|n| "Swimlane #{n}"}
  end
end

