class PullRequest < ApplicationRecord
  belongs_to :repo

  def self.import(remote_pr, remote_repo)
    pull_request = find_by_remote(remote_pr, remote_repo)
    pull_request.update_attributes(
      remote_number: remote_pr[:number],
      remote_title: remote_pr[:title],
      remote_body: remote_pr[:body],
      remote_state: remote_pr[:state],
      remote_head_branch: remote_pr[:head][:ref],
      remote_head_sha: remote_pr[:head][:sha],
      remote_base_branch: remote_pr[:base][:ref],
    )
    pull_request
  end

  def self.find_by_remote(remote_pr, remote_repo)
    pull_request = find_or_initialize_by(remote_id: remote_pr[:id])
    if pull_request.repo_id.blank?
      pull_request.repo = Repo.find_by!(remote_url: remote_repo[:full_name])
    end
    pull_request
  end
end
