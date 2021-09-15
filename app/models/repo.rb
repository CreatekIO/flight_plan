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
  has_many :display_labels, -> {
    where.not(arel_table[:name].matches('status: %')).order(:name)
  }, class_name: 'Label'
  has_many :milestones
  has_many :aliases, class_name: 'RepoAlias'

  scope :auto_deployable, -> { where(auto_deploy: true) }

  octokit_methods(
    :compare, :pull_requests, :merge_pull_request, :create_pull_request,
    :create_ref, :merge, :refs, :delete_branch,
    prefix_with: :slug, add_aliases: true
  )

  octokit_methods :branches, prefix_with: :slug

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

  private

  def set_defaults
    self.deployment_branch ||= DEFAULT_DEPLOYMENT_BRANCH
  end
end
