class RepoEvent < ApplicationRecord
  belongs_to :repo
  belongs_to :user, primary_key: :uid, foreign_key: :remote_user_id
  belongs_to :record, polymorphic: true

  def self.import(payload, repo)
    create(
      repo: repo,
      remote_user_id: payload.dig(:sender, :id),
      remote_username: payload.dig(:sender, :login)
    ) do |event|
      yield(event) if block_given?
    end
  end
end
