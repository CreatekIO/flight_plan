FactoryBot.define do
  factory :label do
    sequence(:remote_id) { generate(:label_id) }
    sequence(:name) { |n| "label #{n}" }
    colour { generate(:hex_colour) }
  end
end
