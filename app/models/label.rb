class Label < ApplicationRecord
  belongs_to :repo
  has_many :labellings, dependent: :destroy
  has_many :tickets, through: :labellings

  STATUS_PREFIX = 'status: '.freeze

  scope :for_display, -> {
    where.not(arel_table[:name].matches("#{STATUS_PREFIX}%")).order(:name)
  }

  def self.import(payload, repo)
    # For Label webhooks the label object is in `:label`, but for
    # Issue webhooks we will just have the label object itself
    payload = payload[:label] || payload

    repo.labels.find_or_initialize_by(remote_id: payload.fetch(:id)).tap do |label|
      label.update(
        name: payload[:name],
        colour: payload[:color]
      )
    end
  end

  def self.for_status?(name)
    name.starts_with?(STATUS_PREFIX)
  end

  def for_swimlane_status?
    self.class.for_status?(name)
  end

  def to_builder
    Jbuilder.new do |json|
      json.extract! self, :id, :name, :colour
      json.repo repo_id
    end
  end
end
