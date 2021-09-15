FactoryBot.define do
  factory :board do
    name { 'My Board' }
    slack_channel { '#general' }
  end
end
