FactoryBot.define do
  factory :ticket, aliases: [:issue] do
    state 'Lobby'
    remote_number { generate(:issue_number) }
    remote_id { generate(:issue_remote_id) }
    remote_title { "Issue No. #{remote_number}" }
    remote_state 'open'
  end
end
