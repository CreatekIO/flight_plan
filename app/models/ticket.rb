class Ticket < ApplicationRecord
  belongs_to :repo
  belongs_to :milestone, optional: true

  has_many :comments, -> {
    order(
      SQLHelper.coalesce(arel_table[:remote_created_at], arel_table[:created_at]).asc
    )
  }, dependent: :destroy
  has_many :board_tickets, dependent: :destroy
  has_many :pull_request_connections
  has_many :pull_requests, -> { order(created_at: :desc) }, through: :pull_request_connections
  has_many :labellings, dependent: :destroy
  # Having `dependent: :destroy` on the `has_many ... through` associations
  # doesn't actually destroy the records, it just ensures that the
  # `after_destroy_commit` callbacks get called on the join models
  has_many :labels, -> { order(:name) }, through: :labellings, dependent: :destroy
  has_many :display_labels, -> { for_display }, through: :labellings, source: :label
  has_many :assignments, class_name: 'TicketAssignment', dependent: :destroy
  has_many :assignees, through: :assignments

  has_one :board_ticket
  has_one :board, through: :board_ticket

  scope :merged, -> { where(merged: true) }
  scope :unmerged, -> { where(merged: false) }

  DELETED_ACTIONS = %w[deleted transferred].freeze

  def self.import(payload, repo, action: nil)
    payload = HashWithIndifferentAccess.new(payload)
    return if payload[:pull_request].present? # actually a PR, ignore

    ticket = repo.tickets.find_or_initialize_by(remote_id: payload.fetch(:id))

    if DELETED_ACTIONS.include?(action)
      ticket.destroy if ticket.persisted?
      return ticket
    end

    if payload[:number].blank?
      Bugsnag.notify('Blank ticket number') do |event|
        event.add_metadata(:debugging, payload: payload, ticket: ticket.attributes)
      end
    end

    ticket.update(
      number: payload[:number],
      title: payload[:title],
      body: payload[:body],
      state: payload[:state],
      remote_created_at: payload[:created_at],
      remote_updated_at: payload[:updated_at],
      creator_remote_id: payload.dig(:user, :id),
      creator_username: payload.dig(:user, :login),
      milestone: Milestone.import(payload[:milestone], ticket.repo),
      remote_closed_at: payload[:closed_at]
    )

    ticket.update_board_tickets_from_remote(payload)
    ticket.update_labels_from_remote(payload)
    ticket.update_assignments_from_remote(payload)
    ticket
  end

  def self.with_slug_and_number(slug, number)
    joins(:repo).merge(Repo.with_slug(slug)).where(number: number)
  end

  def self.find_by_slug_and_number(slug, number)
    with_slug_and_number(slug, number).first
  end

  def self.find_by_html_url(html_url)
    org, repo_name, _, issue_number = URI.parse(html_url).path.split('/')

    find_by_slug_and_number("#{org}/#{repo_name}", issue_number)
  rescue URI::Error
    nil
  end

  def merged_to?(target_branch)
    branch_names.all? do |branch|
      repo.branch_up_to_date?(target_branch, with: branch)
    end
  end

  def branch_names
    repo.branch_names.grep(/##{number}[^0-9]/)
  end

  URL_TEMPLATE = 'https://github.com/%{repo}/issues/%{number}'.freeze

  def html_url
    format(URL_TEMPLATE, repo: repo.slug, number: number)
  end

  def update_board_tickets_from_remote(remote_issue)
    repo.boards.each do |board|
      board_ticket = board_tickets.find_or_initialize_by(board: board)
      board_ticket.update_remote = false # don't sync changes to GitHub
      board_ticket.swimlane = swimlane_from_remote(remote_issue, board)
      board_ticket.swimlane_position = :first if board_ticket.swimlane_id_changed?
      board_ticket.save
    end
  end

  def update_labels_from_remote(remote_issue)
    new_labellings = remote_issue[:labels].map do |remote_label|
      label = Label.import(remote_label, repo)
      labellings.find_or_initialize_by(label: label)
    end

    # Rails will delete removed labellings for us
    update(labellings: new_labellings)
  end

  def update_assignments_from_remote(remote_issue)
    new_assignments = remote_issue[:assignees].map do |remote_user|
      assignments.find_or_initialize_by(assignee_remote_id: remote_user[:id]).tap do |assignment|
        assignment.assignee_username = remote_user[:login]
      end
    end

    # Rails will delete removed assignments for us
    update(assignments: new_assignments)
  end

  def to_builder
    Jbuilder.new do |ticket|
      ticket.id id
      ticket.remote_id remote_id
      ticket.number number
      ticket.title title
      ticket.body body
      ticket.state state

      # TODO: LEGACY - remove
      ticket.remote_number number
      ticket.remote_title title
      ticket.remote_body body
      ticket.remote_state state
    end
  end

  private

  def swimlane_from_remote(remote_issue, board)
    if remote_issue[:state] == 'closed'
      board.closed_swimlane
    else
      status_label = remote_issue[:labels].find do |label|
        Label.for_status?(label[:name])
      end

      if status_label
        board.swimlanes.find_by_label!(status_label[:name])
      else
        board.open_swimlane
      end
    end
  end
end
