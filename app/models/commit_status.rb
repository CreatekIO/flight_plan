class CommitStatus < ApplicationRecord
  belongs_to :repo

  def self.import(payload, repo)
    create(
      remote_id: payload[:id],
      repo: repo,
      state: payload[:state],
      sha: payload[:sha],
      description: payload[:description],
      context: payload[:context],
      url: payload[:target_url],
      # May or may not appear - listed as only being available via API preview
      avatar_url: payload[:avatar_url],
      author_remote_id: payload.dig(:commit, :author, :id),
      author_username: payload.dig(:commit, :author, :login),
      committer_remote_id: payload.dig(:commit, :committer, :id),
      committer_username: payload.dig(:commit, :committer, :login),
      remote_created_at: payload[:created_at],
      # For debugging purposes whilst developing
      payload: payload
    )
  end
end
