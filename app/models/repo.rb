class Repo < ApplicationRecord
  include OctokitClient

  has_many :board_repos, dependent: :destroy
  has_many :boards, through: :board_repos
  has_many :tickets, dependent: :destroy

  def update_merged_tickets
    tickets.unmerged.each do |ticket|
      if ticket.merged_to?('master')
        ticket.update_attributes(merged: true)
      end
    end
  end

  def branch_names
    @branch_names ||= client.branches(remote_url).collect { |b| b[:name] }
  end

  def compare(target_branch, branch)
    client.compare(
      remote_url, 
      target_branch, 
      branch
    )
  end

  def pull_requests
    client.pull_requests(remote_url)
  end

  def create_pull_request(target, source, name, body)
    client.create_pull_request(remote_url, target, source, name, pr_body)
  end

  def create_ref(ref, sha)
    client.create_ref(remote_url, ref, sha)
  end

  def merge(target, source, commit_message: nil)
    client.merge(
      remote_url, 
      target, 
      source, 
      commit_message: commit_message
    )
  end

  def refs(branch)
    client.refs(remote_url, branch)
  end

  def delete_branch(branch)
    client.delete_branch(remote_url, release_branch_name)
  end

end
