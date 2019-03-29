class Label < ApplicationRecord
  belongs_to :repo
  has_many :labellings, dependent: :destroy
  has_many :tickets, through: :labellings

  def self.import(payload, repo)
    # For Label webhooks the label object is in `:label`, but for
    # Issue webhooks we will just have the label object itself
    payload = payload[:label] || payload

    repo.labels.find_or_initialize_by(remote_id: payload.fetch(:id)).tap do |label|
      label.update_attributes(
        name: payload[:name],
        colour: payload[:color]
      )
    end
  end
end
