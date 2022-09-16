class PullRequest < ApplicationRecord
  permissive_enum merge_status: {
    merge_status_unknown: 'unknown',
    merge_conflicts: 'merge_conflicts',
    merge_ok: 'ok'
  }

  # Silence warning about overriding `open` method
  # (which is inherited from Kernel)
  logger.silence do
    permissive_enum state: { open: 'open', closed: 'closed' }
  end

  belongs_to :repo
  has_many :boards, through: :repo, source: :boards
  belongs_to :creator, -> { where(provider: 'github') },
    optional: true, class_name: 'User',
    foreign_key: :creator_remote_id, primary_key: :uid
  has_many :pull_request_connections, autosave: true
  has_many :tickets, through: :pull_request_connections
  has_many :head_commit_statuses, -> (model = nil) {
    if model
      where(repo_id: model.repo_id)
    else # eager-loading/join
      joins(
        table.join(PullRequest.arel_table).on(
          PullRequest.arel_table[:head_sha].eq(table[:sha])
        ).join_sources
      ).where(PullRequest.arel_table[:repo_id].eq(table[:repo_id]))
    end
  }, class_name: 'CommitStatus', foreign_key: :sha, primary_key: :head_sha
  has_many :reviews, class_name: 'PullRequestReview', foreign_key: :remote_pull_request_id, primary_key: :remote_id

  before_save :update_pull_request_connections

  def self.import(payload, repo)
    repo.pull_request_models.find_or_initialize_by(remote_id: payload.fetch(:id)).tap do |pull_request|
      pull_request.update_attributes(
        number: payload[:number],
        title: payload[:title],
        body: payload[:body],
        state: payload[:state],
        head_branch: payload[:head][:ref],
        head_sha: payload[:head][:sha],
        base_branch: payload[:base][:ref],
        merge_status: payload[:mergeable],
        merged: payload[:merged],
        creator_remote_id: payload[:user][:id],
        creator_username: payload[:user][:login],
      )
    end
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

  def merge_status_known?
    !merge_status_unknown?
  end

  def unmerged?
    !merged?
  end

  def release?
    Branch.release?(head_branch)
  end

  URL_TEMPLATE = 'https://github.com/%{repo}/pull/%{number}'.freeze

  def html_url
    format(URL_TEMPLATE, repo: repo.slug, number: number)
  end

  def latest_commit_statuses
    head_commit_statuses
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
    new_connections = referenced_issues.map do |issue|
      query = Repo.with_slug(issue[:repo]).where(tickets: { number: issue[:number] })

      existing = pull_request_connections.joins(ticket: :repo).merge(query).first
      next(existing) if existing.present?

      matching_ticket = associated_tickets.merge(query).first
      next if matching_ticket.blank?

      pull_request_connections.build(ticket: matching_ticket)
    end

    self.pull_request_connections = new_connections.compact
  end

  def referenced_issues
    issues_referenced_in_body.tap do |issues|
      return issues if number_from_branch_name.blank?

      issues.add(repo: repo.slug, number: number_from_branch_name)
    end
  end

  # This can't be an association because Rails doesn't let us use it
  # for an unsaved record (it adds `1=0` to any query)
  def associated_tickets
    associated_repo_ids = boards.flat_map(&:repo_ids).uniq

    Ticket.joins(:repo).where(repo_id: associated_repo_ids)
  end

  def number_from_branch_name
    IssueNumberExtractor.from_branch(head_branch)
  end

  def issues_referenced_in_body
    IssueNumberExtractor.connections(body, current_repo: repo)
  end
end
