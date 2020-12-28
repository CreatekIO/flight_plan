class Milestone < ApplicationRecord
  # Silence warning about overriding `open` method
  # (which is inherited from Kernel)
  logger.silence do
    permissive_enum state: { open: 'open', closed: 'closed' }
  end

  belongs_to :repo
  has_many :tickets, dependent: :nullify

  def self.import(payload, repo)
    return if payload.blank?

    repo.milestones.find_or_initialize_by(remote_id: payload.fetch(:id)).tap do |milestone|
      milestone.update_attributes(
        number: payload[:number],
        title: payload[:title],
        state: payload[:state],
        description: payload[:description],
        due_on: payload[:due_on]
      )
    end
  end
end
