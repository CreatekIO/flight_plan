class Ticket < ApplicationRecord
  belongs_to :repo
  belongs_to :milestone, optional: true

  has_many :comments, -> {
    order('COALESCE(`comments`.`remote_created_at`, `comments`.`created_at`) ASC')
  }, dependent: :destroy
  has_many :board_tickets, dependent: :destroy
  has_many :pull_request_connections
  has_many :pull_requests, -> { order(created_at: :desc) }, through: :pull_request_connections
  has_many :labellings, dependent: :destroy
  has_many :labels, -> { order(:name) }, through: :labellings
  has_many :display_labels, -> {
    where.not(arel_table[:name].matches('status: %')).order(:name)
  }, through: :labellings, source: :label
  has_many :assignments, class_name: 'TicketAssignment', dependent: :destroy
  has_many :assignees, through: :assignments

  scope :merged, -> { where(merged: true) }
  scope :unmerged, -> { where(merged: false) }

  DELETED_ACTIONS = %w[deleted transferred].freeze

  def self.import(remote_issue, remote_repo, action: nil)
    ticket = find_by_remote(remote_issue, remote_repo)

    if DELETED_ACTIONS.include?(action)
      ticket.destroy if ticket.persisted?
      return ticket
    end

    ticket.update_attributes(
      remote_number: remote_issue[:number],
      remote_title: remote_issue[:title],
      remote_body: remote_issue[:body],
      remote_state: remote_issue[:state],
      remote_created_at: remote_issue[:created_at],
      remote_updated_at: remote_issue[:updated_at],
      creator_remote_id: remote_issue.dig(:user, :id),
      creator_username: remote_issue.dig(:user, :login),
      milestone: Milestone.import(remote_issue[:milestone], ticket.repo)
    )

    ticket.update_board_tickets_from_remote(remote_issue)
    ticket.update_labels_from_remote(remote_issue)
    ticket.update_assignments_from_remote(remote_issue)
    ticket
  end

  def self.find_by_remote(remote_issue, remote_repo)
    ticket = Ticket.find_or_initialize_by(remote_id: remote_issue[:id])
    if ticket.repo_id.blank?
      ticket.repo = Repo.find_by!(remote_url: remote_repo[:full_name])
    end
    ticket
  end

  def self.find_by_html_url(html_url)
    org, repo_name, _, issue_number = URI.parse(html_url).path.split('/')

    joins(:repo).find_by(
      repos: { remote_url: "#{org}/#{repo_name}" },
      tickets: { remote_number: issue_number }
    )
  rescue URI::Error
    nil
  end

  def merged_to?(target_branch)
    branch_names.inject(true) do |merged, branch|
      merged && (repo.compare(target_branch, branch).total_commits.zero?)
    end
  end

  def branch_names
    repo.branch_names.grep(/##{remote_number}[^0-9]/)
  end

  URL_TEMPLATE = 'https://github.com/%{repo}/issues/%{number}'.freeze

  def html_url
    format(URL_TEMPLATE, repo: repo.remote_url, number: remote_number)
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
    update_attributes(labellings: new_labellings)
  end

  def update_assignments_from_remote(remote_issue)
    new_assignments = remote_issue[:assignees].map do |remote_user|
      assignments.find_or_initialize_by(assignee_remote_id: remote_user[:id]).tap do |assignment|
        assignment.assignee_username = remote_user[:login]
      end
    end

    # Rails will delete removed assignments for us
    update_attributes(assignments: new_assignments)
  end

  def to_builder
    Jbuilder.new do |ticket|
      ticket.id id
      ticket.remote_id remote_id
      ticket.remote_number remote_number
      ticket.remote_title remote_title
      ticket.remote_body remote_body
      ticket.remote_state remote_state
    end
  end

  private

  def swimlane_from_remote(remote_issue, board)
    if remote_issue[:state] == 'closed'
      board.closed_swimlane
    else
      status_label = remote_issue[:labels].find do |label|
        label[:name].starts_with? 'status:'
      end

      if status_label
        board.swimlanes.find_by_label!(status_label[:name])
      else
        board.open_swimlane
      end
    end
  end
end
