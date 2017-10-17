FactoryGirl.define do
  factory :comment do
    remote_id 1
    remote_author 'jsmith'
    remote_body 'text'
  end
end
