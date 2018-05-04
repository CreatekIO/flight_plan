class RepoEvent < ApplicationRecord
  belongs_to :repo
  belongs_to :user, primary_key: :uid
  belongs_to :record, polymorphic: true
end
