class Branch < ApplicationRecord
  belongs_to :repo
  belongs_to :ticket, optional: true
  has_many :heads, class_name: 'BranchHead', dependent: :destroy
  belongs_to :latest_head, class_name: 'BranchHead', optional: true

  attribute :name, BranchNameType.new
  attribute :base_ref, BranchNameType.new

  def self.import(payload, repo)
    existing_branch = repo.branches.find_by(name: payload[:ref])

    return existing_branch.try(:destroy) if payload[:deleted]

    transaction do
      branch = existing_branch || repo.branches.create!(name: payload[:ref], base_ref: payload[:base_ref])

      new_head = branch.heads.find_or_initialize_by(head_sha: payload[:after])

      unique_commits = Array.wrap(payload[:commits]).map {|commit| commit[:id] }
      unique_commits << payload.dig(:head_commit, :id)
      unique_commits.compact!
      unique_commits.uniq!

      new_head.update!(
        previous_head_sha: payload[:before],
        commits_in_push: unique_commits.size,
        force_push: payload[:forced].present?,
        commit_timestamp: payload.dig(:head_commit, :timestamp),
        author_username: payload.dig(:head_commit, :author, :username),
        committer_username: payload.dig(:head_commit, :committer, :username),
        pusher_remote_id: payload.dig(:sender, :id),
        pusher_username: payload.dig(:sender, :login)
      )

      branch.update!(latest_head: new_head)
      branch
    end
  end

  def self.release?(name)
    name.starts_with?(ReleaseManager::BRANCH_PREFIX)
  end

  def for_release?
    self.class.release?(name)
  end
end
