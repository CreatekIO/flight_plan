class PullRequest < ApplicationRecord
  enum merge_status: {
    merge_status_unknown: 'unknown',
    merge_conflicts: 'merge_conflicts',
    merge_ok: 'ok'
  }

  enum remote_state: { open: 'open', closed: 'closed' }

  belongs_to :repo
  belongs_to :creator, -> { where(provider: 'github') },
    optional: true, class_name: 'User',
    foreign_key: :creator_remote_id, primary_key: :uid
  has_many :pull_request_connections, autosave: true
  has_many :tickets, through: :pull_request_connections
  has_many :reviews, class_name: 'PullRequestReview', foreign_key: :remote_pull_request_id, primary_key: :remote_id

  before_save :update_pull_request_connections

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
      merge_status: remote_pr[:mergeable],
      merged: remote_pr[:merged],
      creator_remote_id: remote_pr[:user][:id],
      creator_username: remote_pr[:user][:login],
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

  # See: https://developer.github.com/v3/pulls/#response-1
  GITHUB_MERGE_STATUSES = {
    nil => 'unknown',
    false => 'merge_conflicts',
    true => 'ok'
  }.freeze

  def merge_status=(value)
    super(GITHUB_MERGE_STATUSES.fetch(value, value))
  end

  def unmerged?
    !merged?
  end

  URL_TEMPLATE = 'https://github.com/%{repo}/pull/%{number}'.freeze

  def html_url
    format(URL_TEMPLATE, repo: repo.remote_url, number: remote_number)
  end

  def latest_commit_statuses
    repo
      .commit_statuses
      .where(sha: remote_head_sha)
      .group_by(&:context)
      .map {|_, records| records.max_by(&:remote_created_at) }
  end

  def latest_reviews
    reviews
      .group_by(&:reviewer_remote_id)
      .map {|_, user_reviews| user_reviews.max_by(&:remote_created_at) }
  end

  private

  def update_pull_request_connections
    @referenced_issue_numbers = nil # reset cache

    to_keep, to_delete = pull_request_connections.includes(:ticket).partition do |conn|
      referenced_issue_numbers.include?(conn.ticket.remote_number)
    end

    to_delete.map(&:destroy)

    existing_issue_numbers = to_keep.map {|conn| conn.ticket.remote_number }

    referenced_issue_numbers.each do |number|
      next if existing_issue_numbers.include?(number)

      matching_ticket = repo.tickets.find_by(remote_number: number)
      next if matching_ticket.blank?

      pull_request_connections.build(ticket: matching_ticket)
    end
  end

  def number_from_branch_name
    IssueNumberExtractor.from_branch(remote_head_branch)
  end

  def numbers_from_body
    IssueNumberExtractor.connections(remote_body)
  end

  def referenced_issue_numbers
    @referenced_issue_numbers ||= [
      *number_from_branch_name,
      *numbers_from_body
    ].to_set
  end
end
