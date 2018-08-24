class Repo < ApplicationRecord
  include OctokitClient

  has_many :board_repos, dependent: :destroy
  has_many :boards, through: :board_repos
  has_many :tickets, dependent: :destroy
  has_many :releases, dependent: :destroy
  has_many :pull_request_models, class_name: 'PullRequest'
  has_many :open_pull_requests, -> { model.open }, class_name: 'PullRequest'
  has_many :pull_request_reviews
  has_many :branches
  has_many :commit_statuses

  def to_builder
    Jbuilder.new do |repo|
      repo.id id
      repo.name name
      repo.remote_url remote_url
    end
  end

  def regex_branches(regex)
    branch_names.grep(regex)
  end

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

  def merge_pull_request(number, comment = '')
    client.merge_pull_request(remote_url, number, comment)
  end

  def create_pull_request(target, source, title, body)
    client.create_pull_request(remote_url, target, source, title, body)
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
    client.delete_branch(remote_url, branch)
  end
end
