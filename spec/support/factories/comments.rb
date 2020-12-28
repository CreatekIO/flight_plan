FactoryBot.define do
  factory :comment do
    remote_id 1
    author_username 'jsmith'
    body 'text'
  end
end
