class BoardTicket < ApplicationRecord
  include RankedModel
  include OctokitClient

  PRELOADS = [
    :open_timesheet,
    ticket: [
      :repo,
      :display_labels,
      :milestone,
      :assignments,
      pull_requests: %i[repo]
    ]
  ].freeze

  belongs_to :board
  belongs_to :ticket
  belongs_to :swimlane
  has_many :timesheets, dependent: :destroy
  has_many :repo_release_board_tickets, dependent: :destroy
  has_many :repo_releases, through: :repo_release_board_tickets
  has_one :open_timesheet, -> { where(ended_at: nil) }, class_name: 'Timesheet'
  has_one :repo, through: :ticket

  after_save :update_timesheet, if: :saved_change_to_swimlane_id?
  after_commit :update_github, on: :update, if: :saved_change_to_swimlane_id?

  scope :for_board, -> (board_id) { where(board_id: board_id) }
  scope :for_repo, -> (repo_id) { where(tickets: { repo_id: repo_id }) }
  scope :preloaded, -> { preload(PRELOADS) }

  ranks :swimlane_sequence, with_same: :swimlane_id

  alias_method :swimlane_position, :swimlane_sequence_position
  alias_method :swimlane_position=, :swimlane_sequence_position=

  attr_writer :update_remote

  octokit_methods(
    :close_issue, :reopen_issue, :replace_all_labels, :labels_for_issue,
    prefix_with: %w[repo.slug ticket.number]
  )

  def state_durations
    timesheets.includes(:swimlane).each_with_object(Hash.new(0)) do |timesheet, durations|
      durations[timesheet.swimlane.name] += timesheet.duration
    end
  end

  def current_state_duration
    Timesheet.format_duration(state_durations[swimlane.name])
  end

  def time_since_last_transition
    Timesheet.format_duration(open_timesheet.duration)
  end

  def displayable_durations(board)
    durations = state_durations

    board.swimlanes.where(display_duration: true).map do |swimlane|
      next if durations[swimlane.name].zero?

      {
        id: swimlane.id,
        name: swimlane.name,
        duration: Timesheet.format_duration(durations[swimlane.name])
      }
    end.compact
  end

  def in_swimlane?(matcher)
    case matcher
    when Numeric
      swimlane_id == matcher
    when Swimlane
      swimlane == matcher
    when Regexp, String
      matcher === swimlane.try(:name)
    else
      raise ArgumentError, "Unsupported: #{matcher.inspect}"
    end
  end

  private

  def handle_ranking
    # Ensure record is already in the right swimlane should we need to rebalance positions
    self.class.unscoped.where(id: id).update_all(swimlane_id: swimlane_id) if prewrite_swimlane_change?

    super
  end

  def prewrite_swimlane_change?
    persisted? && swimlane_position.present? && swimlane_id_changed?
  end

  def update_remote?
    unless defined? @update_remote
      @update_remote = ENV['DO_NOT_SYNC_TO_GITHUB'].blank?
    end
    @update_remote
  end

  def update_timesheet
    time_now = Time.current

    open_timesheet.try(
      :update_attributes,
      ended_at: time_now,
      after_swimlane: swimlane
    )

    timesheets.create!(
      started_at: time_now,
      swimlane: swimlane,
      before_swimlane_id: attribute_before_last_save(:swimlane_id)
    )

    # We've changed what should considered the 'open timesheet',
    # so make Rails (and downstream code) aware of this
    reload_open_timesheet
  end

  def update_github
    return unless update_remote?

    # TODO: need to be able to recover if github does not respond,
    # possibly moving to a background job

    retry_as_app_if_fails(repo) do
      if swimlane_id == closed_swimlane.id
        octokit_close_issue
      elsif attribute_before_last_save(:swimlane_id) == closed_swimlane.id
        octokit_reopen_issue
      end

      octokit_replace_all_labels(new_github_labels)
    end
  end

  def new_github_labels
    non_status_labels = octokit_labels_for_issue
      .map(&:name)
      .reject { |label_name| Label.for_status?(label_name) }

    [
      *non_status_labels,
      *(swimlane.label_name unless [open_swimlane, closed_swimlane].include?(swimlane))
    ]
  end

  def closed_swimlane
    board.closed_swimlane
  end

  def open_swimlane
    board.open_swimlane
  end
end
