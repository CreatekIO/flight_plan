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
  has_many :labels
  has_many :milestones

  octokit_methods(
    :compare, :pull_requests, :merge_pull_request, :create_pull_request,
    :create_ref, :merge, :refs, :delete_branch,
    prefix_with: :remote_url
  )

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
    @branch_names ||= octokit.branches(remote_url).collect { |b| b[:name] }
  end
end
