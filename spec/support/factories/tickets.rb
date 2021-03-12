FactoryBot.define do
  factory :ticket, aliases: [:issue] do
    number { generate(:issue_number) }
    remote_id { generate(:issue_remote_id) }
    title { "Issue No. #{number}" }
    state { 'open' }
  end
end
