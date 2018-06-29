FactoryBot.define do
  factory :ticket, aliases: [:issue] do
    state 'Lobby'
    # Generates odd numbers
    sequence(:remote_number, 1.step(Float::INFINITY, 2).lazy)
    remote_title { "Issue No. #{remote_number}" }
    remote_state 'open'
  end
end
