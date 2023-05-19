class Idea < ApplicationRecord
  belongs_to :submitter, class_name: 'User'
  before_create :set_default_position
  after_create_commit -> { broadcast_append_to "ideas" }

  enum status: { pending: 'pending', accepted: 'accepted' }

  default_scope -> { order(:position) }

  private

  def set_default_position
    self.position ||= self.class.maximum(:position)
  end
end
