class RepoEvent < ApplicationRecord
  belongs_to :repo
  belongs_to :user, primary_key: :uid
  belongs_to :record, polymorphic: true

  def self.import(payload, repo)
    create(
      repo: repo,
      user_id: payload.dig(:sender, :id),
      username: payload.dig(:sender, :login)
    ) do |event|
      yield(event) if block_given?
    end
  end
end
