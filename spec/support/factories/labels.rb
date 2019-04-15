FactoryBot.define do
  factory :label do
    sequence(:remote_id, 1_000_000_000)
    sequence(:name) { |n| "label #{n}" }
    colour { generate(:hex_colour) }
  end
end
