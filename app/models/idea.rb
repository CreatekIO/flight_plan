class Idea < ApplicationRecord
  belongs_to :submitter, class_name: 'User'
  after_create_commit -> { broadcast_append_to "ideas" }
end
