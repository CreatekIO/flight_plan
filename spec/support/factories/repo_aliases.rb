FactoryBot.define do
  factory :repo_alias do
    sequence(:slug) { |n| "aliased/repo_name_#{n}" }
  end
end
