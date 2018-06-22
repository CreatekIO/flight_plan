FactoryGirl.define do
  factory :branch do
    sequence(:name) {|n| "branch-#{n}" }
    base_ref 'master'
  end
end
