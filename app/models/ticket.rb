class Ticket < ApplicationRecord
  belongs_to :repo

  has_many :comments, dependent: :destroy
  has_many :board_tickets, dependent: :destroy
  has_many :pull_request_connections
  has_many :pull_requests, -> { order(created_at: :desc) }, through: :pull_request_connections
  has_many :labellings, dependent: :destroy
  has_many :labels, through: :labellings

  scope :merged, -> { where(merged: true) }
  scope :unmerged, -> { where(merged: false) }

  def self.import(remote_issue, remote_repo)
    ticket = find_by_remote(remote_issue, remote_repo)
    ticket.update_attributes(
      remote_number: remote_issue[:number],
      remote_title: remote_issue[:title],
      remote_body: remote_issue[:body],
      remote_state: remote_issue[:state],
      creator_remote_id: remote_issue.dig(:user, :id),
      creator_username: remote_issue.dig(:user, :login)
    )

    ticket.update_board_tickets_from_remote(remote_issue)
    ticket.update_labels_from_remote(remote_issue)
    ticket
  end

  def self.find_by_remote(remote_issue, remote_repo)
    ticket = Ticket.find_or_initialize_by(remote_id: remote_issue[:id])
    if ticket.repo_id.blank?
      ticket.repo = Repo.find_by!(remote_url: remote_repo[:full_name])
    end
    ticket
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
      bt = board_tickets.find_or_initialize_by(board: board)
      bt.update_remote = false
      bt.swimlane = swimlane_from_remote(remote_issue, board)
      bt.save
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
    if remote_issue['state'] == 'closed'
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
