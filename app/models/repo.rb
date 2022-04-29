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
  has_many :display_labels, -> { for_display }, class_name: 'Label'
  has_many :milestones
  has_many :aliases, class_name: 'RepoAlias'

  has_one :board_repo
  has_one :board, through: :board_repo

  scope :auto_deployable, -> { where(auto_deploy: true) }
  scope :using_app, -> { where.not(remote_installation_id: nil) }

  octokit_methods :branches, :compare, :repo_assignees, prefix_with: :slug
  alias_method :remote_assignees, :octokit_repo_assignees

  URL_TEMPLATE = 'https://github.com/%s'.freeze
  DEFAULT_DEPLOYMENT_BRANCH = 'master'.freeze

  after_initialize :set_defaults

  def self.with_slug(slug)
    where(slug: slug).or(
      where(repo_aliases: { slug: slug })
    ).left_outer_joins(:aliases)
  end

  class << self
    alias_method :with_slugs, :with_slug
  end

  def self.find_by_slug(slug)
    with_slug(slug).first
  end

  def self.find_by_slug!(slug)
    with_slug(slug).first!
  end

  def html_url
    format(URL_TEMPLATE, slug)
  end

  def to_builder
    Jbuilder.new do |repo|
      repo.id id
      repo.name name
      repo.slug slug

      # TODO: LEGACY - remove
      repo.remote_url slug
    end
  end

  def regex_branches(regex)
    branch_names.grep(regex)
  end

  def branch_up_to_date?(name, with:)
    without_octokit_pagination do
      octokit_compare(
        URI.escape(name),
        URI.escape(with),
        # Speed up responses - we don't want the details of each commit,
        # just whether the diff contains any commits
        per_page: 1
      ).total_commits.zero?
    end
  end

  def update_merged_tickets
    tickets.unmerged.each do |ticket|
      if ticket.merged_to?(deployment_branch)
        ticket.update_attributes(merged: true)
      end
    end
  end

  def branch_names
    @branch_names ||= octokit_branches.map { |branch| branch[:name] }
  end

  def uses_app?
    remote_installation_id.present?
  end

  private

  def set_defaults
    self.deployment_branch ||= DEFAULT_DEPLOYMENT_BRANCH
  end

  def octokit_client_options
    token = if uses_app?
      App.access_token_for(installation_id: remote_installation_id)
    else
      OctokitClient::LEGACY_GLOBAL_TOKEN
    end

    { access_token: token }
  end
end
